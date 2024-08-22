import 'dart:async';

import 'package:camerax/src/capture_mode.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'barcode.dart';
import 'camera_args.dart';
import 'camera_exception.dart';
import 'camera_facing.dart';
import 'camera_type.dart';
import 'flash_mode.dart';
import 'resolution_preset.dart';
import 'rotation.dart';
import 'torch_state.dart';
import 'util.dart';

/// A camera controller.
abstract class CameraController {
  /// Arguments for [CameraView].
  ValueNotifier<CameraArgs?> get args;

  /// Torch state of the camera.
  ValueNotifier<TorchState> get torchState;

  /// Flash state of the camera.
  ValueNotifier<FlashState> get flashState;

  /// Availability of torch and flash (can be changed during runtime, e.g. when switching cameras or when the device is overheating).
  ValueNotifier<bool> get isTorchAvailable;
  ValueNotifier<bool> get isFlashAvailable;

  /// Whether the camera has a flash.
  ValueNotifier<bool> get hasFlash;

  /// Whether the camera has a torch.
  ValueNotifier<bool> get hasTorch;

  /// A stream of barcodes.
  Stream<Barcode>? get barcodes;

  /// Create a [CameraController].
  ///
  /// [facing] target facing used to select camera.
  ///
  /// [formats] the barcode formats for image analyzer.
  factory CameraController({
    required CameraType cameraType,
    CameraLensDirection facing = CameraLensDirection.back,
    ResolutionPreset resolutionPreset = ResolutionPreset.max,
    CaptureMode captureMode = CaptureMode.maxQuality,
    PhotoRotation rotation = PhotoRotation.rotationUnset,
  }) =>
      _CameraController(
          facing, cameraType, resolutionPreset, rotation, captureMode);

  /// Start the camera asynchronously.
  Future<void> startAsync();

  /// Switch the torch's state.
  Future<void> setTorchMode(TorchState mode);

  /// Switch the flash's state.
  Future<void> setFlashMode(FlashMode mode);

  /// Release the resources of the camera.
  void dispose();

  Future<bool> isTakingPicture();

  Future<String> takePicture();
}

class _CameraController implements CameraController {
  static const MethodChannel method =
      MethodChannel('yanshouwang.dev/camerax/method');
  static const EventChannel event =
      EventChannel('yanshouwang.dev/camerax/event');

  static const String CAMERA_INDEX = 'camera_index';
  static const String CAMERA_TYPE = 'camera_type';
  static const String CAMERA_RESOLUTION = 'camera_resolution';
  static const String CAMERA_PHOTO_ROTATION = 'camera_photo_rotation';
  static const String CAMERA_CAPTURE_MODE = 'camera_capture_mode';
  static const String CAMERA_FLASH_MODE = 'camera_flash_mode';

  static const undetermined = 0;
  static const authorized = 1;
  static const denied = 2;

  static int? id;
  static StreamSubscription? subscription;

  final CameraLensDirection cameraLensDirection;
  final CameraType cameraType;
  final CaptureMode captureMode;
  final ResolutionPreset resolutionPreset;
  final PhotoRotation rotation;

  @override
  final ValueNotifier<CameraArgs?> args;
  @override
  final ValueNotifier<TorchState> torchState = ValueNotifier(TorchState.off);

  @override
  final ValueNotifier<FlashState> flashState = ValueNotifier(FlashState.off);

  @override
  ValueNotifier<bool> isTorchAvailable = ValueNotifier(false);

  @override
  ValueNotifier<bool> isFlashAvailable = ValueNotifier(false);

  @override
  ValueNotifier<bool> hasFlash = ValueNotifier(false);

  @override
  ValueNotifier<bool> hasTorch = ValueNotifier(false);

  bool _isTakingPicture = false;
  StreamController<Barcode>? barcodesController;

  @override
  Stream<Barcode>? get barcodes => barcodesController?.stream;

  _CameraController(
    this.cameraLensDirection,
    this.cameraType,
    this.resolutionPreset,
    this.rotation,
    this.captureMode,
  ) : args = ValueNotifier(null) {
    // In case new instance before dispose.
    if (id != null) {
      stop();
    }
    id = hashCode;

    subscription =
        event.receiveBroadcastStream().listen((data) => handleEvent(data));
  }

  Future<void> initFlashTorchCapabilities() async {
    final capabilities = await method.invokeMethod('flashTorchCapabilities');
    hasFlash.value = capabilities['hasFlash'];
    hasTorch.value = capabilities['hasTorch'];
    isFlashAvailable.value = capabilities['isFlashAvailable'];
    isTorchAvailable.value = capabilities['isTorchAvailable'];
  }

  void handleEvent(Map<dynamic, dynamic> event) {
    final name = event['name'];
    final data = event['data'];
    switch (name) {
      case 'torchState':
        final state = TorchState.values[data];
        torchState.value = state;
        break;
      case 'flashState':
        final state = FlashState.values[data];
        flashState.value = state;
        break;
      case 'flashAvailable':
        isFlashAvailable.value = data;
        break;
      case 'torchAvailable':
        isTorchAvailable.value = data;
        break;
      default:
        throw UnimplementedError();
    }
  }

  void tryAnalyze(int mode) {
    if (hashCode != id) {
      return;
    }
    method.invokeMethod('analyze', mode);
  }

  @override
  Future<void> startAsync() async {
    ensure('startAsync');
    // Check authorization state.
    var state = await method.invokeMethod('state');
    if (state == undetermined) {
      final result = await method.invokeMethod('request');
      state = result ? authorized : denied;
    }
    if (state != authorized) {
      throw CameraException('Camera access denied',
          'Unauthorized access to camera, check app permission settings');
    }
    // Start camera.
    try {
      final answer = await method.invokeMapMethod<String, dynamic>('start', {
        CAMERA_INDEX: cameraLensDirection.index,
        CAMERA_TYPE: cameraType.index,
        CAMERA_RESOLUTION: resolutionPreset.index,
        CAMERA_PHOTO_ROTATION: rotation.index,
        CAMERA_CAPTURE_MODE: captureMode.index,
        CAMERA_FLASH_MODE: FlashMode.off.index,
      });
      final textureId = answer?['textureId'];
      final size = toSize(answer?['size']);
      args.value = CameraArgs(textureId, size);

      initFlashTorchCapabilities();
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<void> setTorchMode(TorchState mode) async {
    try {
      ensure('torch');
      await method.invokeMethod('torch', mode.index);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<void> setFlashMode(FlashMode mode) async {
    try {
      ensure('flash');
      await method.invokeMethod('flash', mode.index);
    } on PlatformException catch (e) {
      throw CameraException(e.code, e.message);
    }
  }

  @override
  void dispose() {
    if (hashCode == id) {
      stop();
      subscription?.cancel();
      subscription = null;
      id = null;
    }
    barcodesController?.close();
  }

  void stop() => method.invokeMethod('stop');

  void ensure(String name) {
    final message =
        'CameraController.$name called after CameraController.dispose\n'
        'CameraController methods should not be used after calling dispose.';
    assert(hashCode == id, message);
  }

  @override
  Future<String> takePicture() async {
    if (_isTakingPicture) {
      throw CameraException(
        'Previous capture has not returned yet.',
        'takePicture was called before the previous capture returned.',
      );
    }
    try {
      _isTakingPicture = true;
      var result = await method.invokeMethod('capture');
      _isTakingPicture = false;
      return result['path'];
    } on PlatformException catch (e) {
      _isTakingPicture = false;
      throw CameraException(e.code, e.message);
    }
  }

  @override
  Future<bool> isTakingPicture() async {
    return _isTakingPicture;
  }
}
