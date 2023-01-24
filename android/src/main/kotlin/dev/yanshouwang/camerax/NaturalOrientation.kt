package dev.yanshouwang.camerax

import android.content.Context
import android.content.res.Configuration
import android.view.Surface
import android.view.WindowManager
import androidx.core.content.ContextCompat.getSystemService


fun getDeviceNaturalOrientation(context: Context): Int {
    val currentOrientation = getDeviceCurrentOrientation(context)
    if (currentOrientation == Configuration.ORIENTATION_UNDEFINED) {
        return Configuration.ORIENTATION_UNDEFINED
    }
    val windowManager = getWindowManager(context)
    val currentRotation = windowManager.defaultDisplay
        .rotation
    if (currentRotation != Surface.ROTATION_0 && currentRotation != Surface.ROTATION_90 && currentRotation != Surface.ROTATION_180 && currentRotation != Surface.ROTATION_270) {
        return Configuration.ORIENTATION_UNDEFINED
    }
    if (currentOrientation == Configuration.ORIENTATION_PORTRAIT) {
        return if (currentRotation == Surface.ROTATION_0
            || currentRotation == Surface.ROTATION_180
        ) {
            Configuration.ORIENTATION_PORTRAIT
        } else Configuration.ORIENTATION_LANDSCAPE
    }
    return if (currentRotation == Surface.ROTATION_0
        || currentRotation == Surface.ROTATION_180
    ) {
        Configuration.ORIENTATION_LANDSCAPE
    } else Configuration.ORIENTATION_PORTRAIT
}

fun getDeviceCurrentOrientation(context: Context): Int {
    val orientation = context.resources.configuration.orientation
    return if (orientation != Configuration.ORIENTATION_LANDSCAPE
        && orientation != Configuration.ORIENTATION_PORTRAIT
    ) {
        Configuration.ORIENTATION_UNDEFINED
    } else orientation
}

private fun getWindowManager(context: Context): WindowManager {
    return context
        .getSystemService(Context.WINDOW_SERVICE) as WindowManager
}

fun getDeviceDefaultOrientation(context: Context): Int {
    val windowManager = getWindowManager(context)
    val orientation = context.resources.configuration.orientation
    val rotation = windowManager!!.defaultDisplay.rotation

    if (orientation == Configuration.ORIENTATION_UNDEFINED) {
        return Configuration.ORIENTATION_UNDEFINED
    }

    return if ((rotation == Surface.ROTATION_0 || rotation == Surface.ROTATION_180) &&
        orientation == Configuration.ORIENTATION_LANDSCAPE
        || (rotation == Surface.ROTATION_90 || rotation == Surface.ROTATION_270) &&
        orientation == Configuration.ORIENTATION_PORTRAIT
    ) {
        Configuration.ORIENTATION_LANDSCAPE
    } else {
        Configuration.ORIENTATION_PORTRAIT
    }
}