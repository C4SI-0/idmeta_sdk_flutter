package com.idmeta_sdk_flutter.network.client.model

data class CaptureLivenessResponse(
    val probability: Float,
    val score: Float?,
    val detailedResult: Array<Float>?
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as CaptureLivenessResponse

        if (probability != other.probability) return false
        if (score != other.score) return false
        if (!detailedResult.contentEquals(other.detailedResult)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = probability.hashCode()
        result = 31 * result + (score?.hashCode() ?: 0)
        result = 31 * result + detailedResult.contentHashCode()
        return result
    }
}
