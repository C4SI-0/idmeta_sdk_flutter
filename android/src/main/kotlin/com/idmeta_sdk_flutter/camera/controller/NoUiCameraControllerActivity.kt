package com.idmeta_sdk_flutter.camera.controller

import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.ProgressBar
import android.widget.TextView
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isVisible
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.idmeta_sdk_flutter.R

// Import our new safe config object
import com.idmeta_sdk_flutter.IadSdkConfig

class NoUiCameraControllerActivity : AppCompatActivity(R.layout.no_ui_activity) {
    private lateinit var startButton: Button
    private lateinit var progressBar: ProgressBar
    private lateinit var faceRecognitionHintView: TextView

    private val viewModel: CameraControllerViewModel by viewModels {
        val intent = intent
        // Get the dynamic data from the intent
        val authToken = intent.getStringExtra("AUTH_TOKEN") ?: ""
        val templateId = intent.getStringExtra("TEMPLATE_ID") ?: ""
        val verificationId = intent.getStringExtra("VERIFICATION_ID") ?: ""
        
        if (authToken.isEmpty() || templateId.isEmpty() || verificationId.isEmpty()) {
            Log.e("NoUiController", "Auth token or IDs are missing from the intent.")
        }
        
        // Use the new safe config object to get the rest of the configuration.
        CameraControllerViewModel.CameraControllerViewModelFactory(
            application, // Pass the application context
            authToken,
            templateId,
            verificationId,
            IadSdkConfig.isPreviewEnabled,
            IadSdkConfig.payloadSize
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        lifecycle.addObserver(viewModel)

        startButton = findViewById(R.id.startButton)
        progressBar = findViewById(R.id.progressBar)
        faceRecognitionHintView = findViewById(R.id.faceRecognitionHintView)

        viewModel.uiState.observe(this) { uiState ->
            uiState ?: return@observe
            when (uiState) {
                UiState.Idle -> {
                    startButton.isVisible = true
                    progressBar.isVisible = false
                    faceRecognitionHintView.isVisible = false
                }
                UiState.FaceDetection -> {
                    startButton.isVisible = false
                    progressBar.isVisible = false
                    faceRecognitionHintView.isVisible = true
                }
                UiState.PhotoProcessing -> {
                    progressBar.isVisible = true
                    faceRecognitionHintView.isVisible = false
                }
            }
        }

        viewModel.faceDetectionHint.observe(this) { hint ->
            hint ?: return@observe
            faceRecognitionHintView.text = hint
        }

        viewModel.errorMessage.observe(this) { errorMessage ->
            errorMessage ?: return@observe
            showErrorMessage(errorMessage)
        }

        // Note: This call might need a PreviewView parameter if the no-UI version
        // still uses one. If it's truly no-UI, the method might need to be overloaded.
        // For now, leaving as is, assuming createCameraController is flexible.
        viewModel.createCameraController(applicationContext, this)

        startButton.setOnClickListener(viewModel.onStartButtonClickListener)

        viewModel.activityFinishData.observe(this) { intent ->
            setResult(RESULT_OK, intent)
            finish()
        }
    }

    private fun showErrorMessage(message: String) {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.error_title)
            .setOnDismissListener { viewModel.uiState.value = UiState.Idle }
            .setMessage(message)
            .show()
    }

    private fun showIadResult(message: String) {
        MaterialAlertDialogBuilder(this)
            .setTitle(R.string.response_title)
            .setOnDismissListener { viewModel.uiState.value = UiState.Idle }
            .setMessage(message)
            .show()
    }
}