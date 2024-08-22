import 'package:camerax/camerax.dart';
import 'package:flutter/material.dart';

import 'app_bar.dart';

class CaptureView extends StatefulWidget {
  const CaptureView({Key? key}) : super(key: key);

  @override
  State<CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<CaptureView> {
  late final CameraController cameraController;

  bool showTorchButton = false;
  bool showFlashButton = false;

  FlashState flashState = FlashState.off;
  TorchState torchState = TorchState.off;

  void _handleTorchAvailable() {
    setState(() {
      showTorchButton = cameraController.hasTorch.value &&
          cameraController.isTorchAvailable.value;
    });
  }

  void _handleFlashAvailable() {
    setState(() {
      showFlashButton = cameraController.hasFlash.value &&
          cameraController.isFlashAvailable.value;
    });
  }

  @override
  void initState() {
    super.initState();
    cameraController = CameraController(
      cameraType: CameraType.picture,
      captureMode: CaptureMode.maxQuality,
    );
    start();
  }

  void start() async {
    await cameraController.startAsync();
    cameraController.isTorchAvailable.addListener(_handleTorchAvailable);
    cameraController.hasTorch.addListener(_handleTorchAvailable);
    _handleTorchAvailable();

    cameraController.isFlashAvailable.addListener(_handleFlashAvailable);
    cameraController.hasFlash.addListener(_handleFlashAvailable);
    _handleFlashAvailable();

    cameraController.flashState.addListener(() {
      setState(() {
        flashState = cameraController.flashState.value;
      });
    });

    cameraController.torchState.addListener(() {
      setState(() {
        torchState = cameraController.torchState.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ExampleAppBar(title: 'Capture'),
      body: Stack(
        children: [
          Container(color: Colors.blue),
          CameraPreview(cameraController),
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              margin: const EdgeInsets.only(bottom: 32.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: Icon(Icons.camera),
                          onPressed: () => _takePicture(context),
                          label: Text('Capture'),
                        ),
                        Container(
                          alignment: Alignment.bottomCenter,
                          child: IconButton(
                            icon: Icon(
                                !showTorchButton
                                    ? Icons.flashlight_off_outlined
                                    : switch (torchState) {
                                        TorchState.off => Icons.flashlight_off,
                                        TorchState.on => Icons.flashlight_on,
                                        TorchState.auto =>
                                          Icons.flashlight_on_outlined,
                                      },
                                color: torchState == TorchState.off
                                    ? Colors.grey
                                    : Colors.white),
                            iconSize: 32.0,
                            onPressed: () {
                              if (!showTorchButton) {
                                return;
                              }
                              switch (cameraController.torchState.value) {
                                case TorchState.off:
                                  cameraController.setTorchMode(TorchState.on);
                                  break;
                                case TorchState.on:
                                  cameraController
                                      .setTorchMode(TorchState.auto);
                                  break;
                                case TorchState.auto:
                                  cameraController.setTorchMode(TorchState.off);
                                  break;
                              }
                            },
                          ),
                        ),
                        Container(
                          alignment: Alignment.bottomCenter,
                          child: IconButton(
                            icon: Icon(
                                !showFlashButton
                                    ? Icons.flash_off_outlined
                                    : switch (flashState) {
                                        FlashState.off => Icons.flash_off,
                                        FlashState.on => Icons.flash_on,
                                        FlashState.auto => Icons.flash_auto,
                                      },
                                color: flashState == FlashState.off
                                    ? Colors.grey
                                    : Colors.white),
                            iconSize: 32.0,
                            onPressed: () {
                              if (!showFlashButton) {
                                return;
                              }
                              switch (cameraController.flashState.value) {
                                case FlashState.off:
                                  cameraController.setFlashMode(FlashMode.on);
                                  break;
                                case FlashState.on:
                                  cameraController.setFlashMode(FlashMode.auto);
                                  break;
                                case FlashState.auto:
                                  cameraController.setFlashMode(FlashMode.off);
                                  break;
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture(BuildContext context) async {
    if (!(await cameraController.isTakingPicture())) {
      print('Taking picture!');
      try {
        var result = await cameraController.takePicture();
        print('CAMERA RESULT $result');
        await Navigator.pushNamed(context, 'preview', arguments: result);
      } on CameraException catch (e) {
        print('Camera Error, reason: $e');
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Image capture error'),
            content: Text('${e.toString()}'),
          ),
        );
      }
    } else {
      print('Not taking picture!');
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
