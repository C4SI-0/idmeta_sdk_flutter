package com.idmeta_sdk_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import com.idmeta_sdk_flutter.camera.controller.CameraControllerActivity
import net.idrnd.face.iad.capture.License
import net.idrnd.face.iad.capture.LicenseException
import net.idrnd.face.iad.capture.LicenseType
import com.idmeta_sdk_flutter.IadSdkConfig

class IdmetaSdkFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private var activityBinding: ActivityPluginBinding? = null

    companion object {
        private const val TAG = "IdmetaSdkFlutterPlugin"
        private const val LIVENESS_REQUEST_CODE = 1001

        // --- The license key is now stored securely inside the plugin ---
        private const val LICENSE_KEY = "AQAAAAAAAAAyMDI2LTA3LTEzMgAAAFwmk+8Ae6U/nZzAgLkJhbMleJPIGkbof2IgrGjgpjfGCNh1rAE99DlB7y79QiVh9m0IaODHzxSmBsAdZoCeKfpsNjox7KLy7C5LPsh+kV10MmazOY5h8QU+BsOTPmHTGCYczBzAX5WjPStP2tmkVZOIsuOHNWfR0JpXtbJ1jpk7EbMYehI+BSmp6yZTDQXhl0nVhC/fAcuvt4tQDcZZi0J4D7scHIkt4aa5QZQXxEuESsfma+s53/tgh4MxUhJ7ieZbAwqojGGCoyr3oV1+cUVXBs0pagvjuTiKs4KCnpXGwzLo8WChRJVCmqYTT9xgyY/eiK/+3TdRw1Y4ZKvPOXg="
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        // --- THIS IS THE NEW AUTOMATIC INITIALIZATION LOGIC ---
        // It runs once when the plugin is loaded by the Flutter engine.
        try {
            License.setLicense(LICENSE_KEY, LicenseType.FaceDetector)
            IadSdkConfig.licenseException = null // Clear any old exception.
        } catch (e: LicenseException) {
            android.util.Log.e(TAG, "FATAL: ID R&D License initialization failed", e)
            // Store the exception so our activities (like PermissionRequesterActivity) 
            // can check it and show an error.
            IadSdkConfig.licenseException = e 
        }

        // The rest of the method sets up the channel as before.
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "net.idrnd.iad/liveness")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        this.activity = binding.activity
        this.activityBinding = binding

        binding.addActivityResultListener { requestCode, resultCode, data ->
            if (requestCode == LIVENESS_REQUEST_CODE) {
                if (resultCode == Activity.RESULT_OK) {
                    val iadResult = data?.getStringExtra("iadResult")
                    val errorMessage = data?.getStringExtra("errorMessage")

                    when {
                        iadResult != null -> pendingResult?.success(iadResult)
                        errorMessage != null -> pendingResult?.error("LIVENESS_FAILED", errorMessage, null)
                        else -> pendingResult?.error("UNKNOWN_ERROR", "An unknown error occurred.", null)
                    }
                } else {
                    pendingResult?.error("CANCELED", "Liveness check was canceled by the user.", null)
                }

                pendingResult = null
                return@addActivityResultListener true // event handled
            }
            return@addActivityResultListener false // not handled
        }
    }

    override fun onDetachedFromActivity() {
        this.activity = null
        this.activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "startLiveness") {
            if (activity == null) {
                result.error("NO_ACTIVITY", "Plugin is not attached to a foreground activity.", null)
                return
            }

            this.pendingResult = result

            val authToken = call.argument<String>("authToken")
            val templateId = call.argument<String>("templateId")
            val verificationId = call.argument<String>("verificationId")

            if (authToken == null || templateId == null || verificationId == null) {
                result.error("MISSING_ARGUMENTS", "AuthToken, TemplateId, or VerificationId is missing.", null)
                return
            }

            startLivenessCheck(authToken, templateId, verificationId)
        } else {
            result.notImplemented()
        }
    }

    private fun startLivenessCheck(authToken: String, templateId: String, verificationId: String) {
        val intent = Intent(activity, CameraControllerActivity::class.java).apply {
            putExtra("AUTH_TOKEN", authToken)
            putExtra("TEMPLATE_ID", templateId)
            putExtra("VERIFICATION_ID", verificationId)
        }
        activity?.startActivityForResult(intent, LIVENESS_REQUEST_CODE)
    }
}