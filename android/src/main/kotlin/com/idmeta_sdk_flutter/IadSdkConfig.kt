package com.idmeta_sdk_flutter // Use your plugin's package name

import net.idrnd.android.idlive.face.iad.camera.controller.IadOptions

/**
 * A singleton object to hold global configuration for the IDMETA SDK plugin.
 * This is a safe, global data container that won't crash the app.
 */
object IadSdkConfig {

    // These are the properties your other classes need.
    var isPreviewEnabled = true
    var payloadSize = IadOptions.PayloadSize.Normal

    // We can store the license exception state here.
    var licenseException: Throwable? = null
}