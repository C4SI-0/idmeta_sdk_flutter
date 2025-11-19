package com.idmeta_sdk_flutter.network.client

import com.idmeta_sdk_flutter.network.client.model.CheckLivenessWithIadResponse

/**
 * IAD with face liveness check client interface.
 */
interface IadWithFaceLivenessCheckClient : IadClient<CheckLivenessWithIadResponse> {
    /**
     * Request a check on injection attacks and on a face liveness.
     *
     * @param encryptedBundle encrypted bundle which is produced by IAD Android library.
     * @return response with information about IAD status and a face liveness.
     */
    override fun request(encryptedBundle: ByteArray): CheckLivenessWithIadResponse
}
