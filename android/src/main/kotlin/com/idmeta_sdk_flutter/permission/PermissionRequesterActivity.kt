package com.idmeta_sdk_flutter.permission

import android.Manifest.permission.CAMERA
import android.app.AlertDialog
import android.content.Intent
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.Bundle
import android.widget.Button
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
// REMOVED: import com.idmeta_sdk_flutter.IadApplication
import com.idmeta_sdk_flutter.R
import com.idmeta_sdk_flutter.camera.selector.CameraControllerSelectorActivity

// Import our new safe config object
import com.idmeta_sdk_flutter.IadSdkConfig

class PermissionRequesterActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Use the new safe config object to check for a license exception.
        IadSdkConfig.licenseException?.let {
            AlertDialog.Builder(this)
                .setTitle(getString(R.string.license))
                .setMessage(getString(R.string.during_license_evaluation_an_error_occurs, it.message))
                .setOnDismissListener {
                    finish()
                }
                .show()
            return
        }

        if (isCameraPermissionGranted()) {
            launchCameraControllerSelectorActivity()
            return
        }

        setContentView(R.layout.permissions_request_activity)

        findViewById<Button>(R.id.requestPermissionButton).setOnClickListener {
            ActivityCompat.requestPermissions(this, arrayOf(CAMERA), PERMISSION_CAMERA_REQUEST)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        if (requestCode == PERMISSION_CAMERA_REQUEST && isCameraPermissionGranted()) {
            launchCameraControllerSelectorActivity()
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun isCameraPermissionGranted(): Boolean {
        return ContextCompat.checkSelfPermission(baseContext, CAMERA) == PERMISSION_GRANTED
    }

    private fun launchCameraControllerSelectorActivity() {
        val intent = Intent(this, CameraControllerSelectorActivity::class.java)
        startActivity(intent)
        finish()
    }

    companion object {
        private const val PERMISSION_CAMERA_REQUEST = 1
    }
}