package dev.yanshouwang.camerax

import android.annotation.SuppressLint
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** CameraXPlugin */
class CameraXPlugin : FlutterPlugin, ActivityAware {
    private var flutter: FlutterPlugin.FlutterPluginBinding? = null
    private var activity: ActivityPluginBinding? = null
    private var handler: CameraXHandler? = null
    private var method: MethodChannel? = null
    private var event: EventChannel? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.v("CameraXPlugin", "onAttachedToEngine")
        this.flutter = binding
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.v("CameraXPlugin", "onDetachedFromEngine")
        this.flutter = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.v("CameraXPlugin", "onAttachedToActivity")
        activity = binding
        handler = CameraXHandler(activity!!.activity, flutter!!.textureRegistry)
        method = MethodChannel(flutter!!.binaryMessenger, "yanshouwang.dev/camerax/method")
        event = EventChannel(flutter!!.binaryMessenger, "yanshouwang.dev/camerax/event")
        method!!.setMethodCallHandler(handler)
        event!!.setStreamHandler(handler)
        activity!!.addRequestPermissionsResultListener(handler!!)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.v("CameraXPlugin", "onReattachedToActivityForConfigChanges")
        onAttachedToActivity(binding)
    }

    @SuppressLint("UnsafeOptInUsageError")
    override fun onDetachedFromActivity() {
        Log.v("CameraXPlugin", "onDetachedFromActivity")
        // force release camera if dart is not able to do this before onDetachedFromActivity
        // otherwise after onDetachedFromActivity dart is not able to send stop because handler, method, event is set to null
        var h: CameraXHandler = handler!!
        h.onMethodCall(MethodCall("stop", null), FakeResult());
        activity!!.removeRequestPermissionsResultListener(handler!!)
        event!!.setStreamHandler(null)
        method!!.setMethodCallHandler(null)
        event = null
        method = null
        handler = null
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.v("CameraXPlugin", "onDetachedFromActivityForConfigChanges")
        onDetachedFromActivity()
    }
}

class FakeResult : MethodChannel.Result {
    override fun success(p0: Any?) {
        Log.v("FakeResult", "success")
    }

    override fun error(p0: String, p1: String?, p2: Any?) {
    }

    override fun notImplemented() {
    }
}

