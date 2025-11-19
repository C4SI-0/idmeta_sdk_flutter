package com.idmeta_sdk_flutter.network.client.model

data class CheckLivenessWithIadResponse(
    val faceLiveness: FaceLivenessResponse?,
    val captureLiveness: CaptureLivenessResponse
)
