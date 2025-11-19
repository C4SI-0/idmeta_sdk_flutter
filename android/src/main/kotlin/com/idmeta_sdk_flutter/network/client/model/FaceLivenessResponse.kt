package com.idmeta_sdk_flutter.network.client.model

data class FaceLivenessResponse(
    val score: Float?,
    val quality: Float?,
    val probability: Float?,
    val digitalManipulationCheck: DigitalManipulationCheck?
)
