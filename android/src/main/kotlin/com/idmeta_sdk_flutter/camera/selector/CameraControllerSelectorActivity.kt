package com.idmeta_sdk_flutter.camera.selector

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.switchmaterial.SwitchMaterial
import net.idrnd.android.idlive.face.iad.camera.controller.IadOptions
// REMOVED: import com.idmeta_sdk_flutter.IadApplication
import com.idmeta_sdk_flutter.R
import com.idmeta_sdk_flutter.camera.controller.CameraControllerActivity
import com.idmeta_sdk_flutter.camera.controller.NoUiCameraControllerActivity

// Import our new safe config object
import com.idmeta_sdk_flutter.IadSdkConfig

class CameraControllerSelectorActivity : AppCompatActivity(R.layout.camera_controller_selector_activity) {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        findViewById<Button>(R.id.openCameraScreenButton).setOnClickListener {
            startActivity(createIntent())
        }

        // Use the new safe config object to get and set the isPreviewEnabled value.
        findViewById<SwitchMaterial>(R.id.usePreviewSwitch).apply {
            isChecked = IadSdkConfig.isPreviewEnabled
            setOnCheckedChangeListener { _, isChecked ->
                IadSdkConfig.isPreviewEnabled = isChecked
            }
        }

        // Use the new safe config object to get and set the payloadSize value.
        findViewById<SwitchMaterial>(R.id.payloadSizeSwitch).apply {
            isChecked = IadSdkConfig.payloadSize == IadOptions.PayloadSize.Small
            setOnCheckedChangeListener { _, isChecked ->
                IadSdkConfig.payloadSize = if (isChecked) IadOptions.PayloadSize.Small else IadOptions.PayloadSize.Normal
            }
        }
    }

    private fun createIntent(): Intent {
        // Use the new safe config object to decide which Activity to launch.
        val intent = if (IadSdkConfig.isPreviewEnabled) {
            Intent(this, CameraControllerActivity::class.java)
        } else {
            Intent(this, NoUiCameraControllerActivity::class.java)
        }
        return intent
    }
}