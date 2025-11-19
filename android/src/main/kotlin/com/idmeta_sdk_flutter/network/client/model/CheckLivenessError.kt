package com.idmeta_sdk_flutter.network.client.model

import net.idrnd.facesdk.FaceException

data class CheckLivenessError(val error: String, val errorCode: String) {
    @Throws(IllegalArgumentException::class)
    fun toFaceException(): FaceException {
        return FaceException(FaceException.Status.valueOf(errorCode), error)
    }
}
