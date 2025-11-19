package com.idmeta_sdk_flutter.network.client

/**
 * IAD client interface.
 */
interface IadClient<T> {
    /**
     * Request a check on injection attacks.
     *
     * @param encryptedBundle encrypted bundle which is produced by IAD Android library.
     * @return response with information about IAD status.
     */
    fun request(encryptedBundle: ByteArray): T
}
