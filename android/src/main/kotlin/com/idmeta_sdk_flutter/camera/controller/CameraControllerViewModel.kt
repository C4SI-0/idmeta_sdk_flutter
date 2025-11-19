package com.idmeta_sdk_flutter.camera.controller

import android.app.Application
import android.content.Context
import android.content.Intent
import android.util.Size
import android.view.View.OnClickListener
import androidx.camera.view.PreviewView
import androidx.lifecycle.*
import androidx.lifecycle.viewmodel.CreationExtras
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import net.idrnd.android.idlive.face.camera.controller.OnCameraErrorListener
import net.idrnd.android.idlive.face.camera.detection.result.OnDetectionErrorListener
import net.idrnd.android.idlive.face.camera.process.ImageProcessor
import net.idrnd.android.idlive.face.detection.local.*
import net.idrnd.android.idlive.face.detection.model.OptionalCheck
import net.idrnd.android.idlive.face.iad.camera.controller.IadCameraController
import net.idrnd.android.idlive.face.iad.camera.controller.IadOptions
import net.idrnd.android.idlive.face.iad.camera.controller.PayloadOptions
import net.idrnd.android.idlive.face.iad.camera.process.BundleProcessor
import com.idmeta_sdk_flutter.network.client.DefIadWithFaceLivenessCheckClient
import org.json.JSONObject
import com.idmeta_sdk_flutter.IadSdkConfig

class CameraControllerViewModel(
    app: Application,
    private val authToken: String,
    private val templateId: String,
    private val verificationId: String,
    private val isPreviewEnabled: Boolean,
    private val payloadSize: IadOptions.PayloadSize
) : AndroidViewModel(app), DefaultLifecycleObserver {

    // ... (All of your existing ViewModel logic is fine) ...
    val errorMessage = MutableLiveData<String>()
    val faceDetectionHint = MutableLiveData<String>()
    val uiState = MutableLiveData<UiState>()
    val activityFinishData = MutableLiveData<Intent>()
    private var capturedImageData: ByteArray? = null

    val onStartButtonClickListener = OnClickListener {
        cameraController.startDetection()
        uiState.value = UiState.FaceDetection
    }

    private val iadClient = DefIadWithFaceLivenessCheckClient(IDLIVE_FACE_SERVER_URL)
    private var iadFaceDetector: LocalFaceDetector? = null
    private lateinit var cameraController: IadCameraController

    fun createCameraController(context: Context, lifecycleOwner: LifecycleOwner, previewView: PreviewView? = null) {
        val builder = CameraControllerBuilder()
        if (previewView != null) { builder.setPreviewView(previewView) }
        iadFaceDetector = LocalFaceDetector(context, FaceDetectorOptions.createFaceDetectorOptions(listOf(OptionalCheck.FaceNotCentered, OptionalCheck.SunglassesDetected)))
        
        cameraController = builder.setFaceDetector(iadFaceDetector!!)
            .setPayloadSize(this.payloadSize)
            .build(context, lifecycleOwner)
            
        cameraController.setPayloadOptions(PayloadOptions.createPayloadOptions(this.payloadSize, "some-external-metadata"))
        // ... (rest of the createCameraController method is fine) ...
        cameraController.onCameraErrorListener = OnCameraErrorListener { error -> errorMessage.postValue(error.message) }
        cameraController.onDetectionErrorListener = OnDetectionErrorListener { exception -> errorMessage.postValue(exception.message) }

        cameraController.photoProcessor = object : ImageProcessor {
            override fun process(data: ByteArray, size: Size, format: Int, rotationAngle: Int) {
                capturedImageData = data
                uiState.postValue(UiState.PhotoProcessing)
            }
        }

        cameraController.bundleProcessor = object : BundleProcessor {
            override fun process(bundle: ByteArray) {
                viewModelScope.launch(Dispatchers.Default) {
                    val resultIntent = Intent()
                    try {
                        val rawJsonResponse = iadClient.getRawResponse(
                            bundle,
                            capturedImageData,
                            authToken,
                            templateId,
                            verificationId
                        )
                        
                        val json = JSONObject(rawJsonResponse)
                        val result = json.getJSONObject("result")
                        val response = result.getJSONObject("response")
                        val captureLiveness = response.getJSONObject("capture_liveness")
                        val probability = captureLiveness.getDouble("probability")
                        val msg = "Success"
                        resultIntent.putExtra("iadResult", msg)
                    } catch (e: Exception) {
                        resultIntent.putExtra("errorMessage", e.message ?: "An unknown error occurred")
                    }
                    activityFinishData.postValue(resultIntent)
                }
            }
        }

        iadFaceDetector?.onDetectionResultListener = OnDetectionResultListener { result ->
            val shortDescription = result.shortDescription
            faceDetectionHint.postValue(shortDescription.name)
        }
    }

    override fun onStart(owner: LifecycleOwner) { super.onStart(owner); cameraController.openCamera(); uiState.value = UiState.Idle }
    override fun onResume(owner: LifecycleOwner) { super.onResume(owner); cameraController.startPreview() }
    override fun onPause(owner: LifecycleOwner) { super.onPause(owner); cameraController.stopPreview() }
    override fun onStop(owner: LifecycleOwner) { super.onStop(owner); cameraController.closeCamera() }
    override fun onCleared() { super.onCleared(); cameraController.close(); iadFaceDetector?.close() }

    // --- THIS IS THE FIX ---
    // The Factory constructor now correctly accepts the Application object
    class CameraControllerViewModelFactory(
        private val application: Application,
        private val authToken: String,
        private val templateId: String,
        private val verificationId: String,
        private val isPreviewEnabled: Boolean,
        private val payloadSize: IadOptions.PayloadSize
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T {
            if (modelClass.isAssignableFrom(CameraControllerViewModel::class.java)) {
                return CameraControllerViewModel(
                    application, // Pass the application
                    authToken,
                    templateId,
                    verificationId,
                    isPreviewEnabled,
                    payloadSize
                ) as T
            }
            throw IllegalArgumentException("Unknown ViewModel class")
        }
    }

    companion object {
        private const val IDLIVE_FACE_SERVER_URL = "https://integrate.idmetagroup.com/api/v1/verification"
    }
}