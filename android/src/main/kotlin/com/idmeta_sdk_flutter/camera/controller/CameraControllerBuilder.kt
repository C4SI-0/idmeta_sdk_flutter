package com.idmeta_sdk_flutter.camera.controller

import android.content.Context
import androidx.camera.view.PreviewView
import androidx.lifecycle.LifecycleOwner
import net.idrnd.android.idlive.face.camera.images.Jpeg
import net.idrnd.android.idlive.face.detection.interfaces.AutocaptureFaceDetector
import net.idrnd.android.idlive.face.iad.camera.controller.IadCameraController
import net.idrnd.android.idlive.face.iad.camera.controller.IadOptions

class CameraControllerBuilder {
    private var faceDetector: AutocaptureFaceDetector<Jpeg, *>? = null
    private var previewView: PreviewView? = null
    private var payloadSize: IadOptions.PayloadSize? = null

    fun setPayloadSize(payloadSize: IadOptions.PayloadSize): CameraControllerBuilder {
        this.payloadSize = payloadSize
        return this
    }

    fun setFaceDetector(faceDetector: AutocaptureFaceDetector<Jpeg, *>): CameraControllerBuilder {
        this.faceDetector = faceDetector
        return this
    }

    fun setPreviewView(previewView: PreviewView): CameraControllerBuilder {
        this.previewView = previewView
        return this
    }

    fun build(context: Context, lifecycleOwner: LifecycleOwner): IadCameraController {
        return if (previewView == null) {
            if (faceDetector == null) {
                if (payloadSize == null) {
                    IadCameraController(context, lifecycleOwner)
                } else {
                    IadCameraController(context, lifecycleOwner, IadOptions.createIadOptions(payloadSize!!))
                }
            } else {
                if (payloadSize == null) {
                    IadCameraController(faceDetector!!, context, lifecycleOwner)
                } else {
                    IadCameraController(
                        faceDetector!!,
                        context,
                        lifecycleOwner,
                        IadOptions.createIadOptions(payloadSize!!)
                    )
                }
            }
        } else {
            if (faceDetector == null) {
                if (payloadSize == null) {
                    IadCameraController(previewView!!, lifecycleOwner)
                } else {
                    IadCameraController(
                        previewView!!,
                        lifecycleOwner,
                        IadOptions.createIadOptions(payloadSize!!)
                    )
                }
            } else {
                if (payloadSize == null) {
                    IadCameraController(faceDetector!!, previewView!!, lifecycleOwner)
                } else {
                    IadCameraController(
                        faceDetector!!,
                        previewView!!,
                        lifecycleOwner,
                        IadOptions.createIadOptions(payloadSize!!)
                    )
                }
            }
        }
    }
}
