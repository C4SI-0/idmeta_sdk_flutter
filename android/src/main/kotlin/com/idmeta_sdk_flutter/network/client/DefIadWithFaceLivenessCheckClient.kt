package com.idmeta_sdk_flutter.network.client

import android.util.Base64
import okhttp3.logging.HttpLoggingInterceptor
import java.io.IOException
import java.util.concurrent.TimeUnit
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import okhttp3.Response
import org.json.JSONObject

/**
 * Networking client to communicate with the custom PHP backend.
 */
class DefIadWithFaceLivenessCheckClient {
    private val httpClient: OkHttpClient
    private val serverUrl: String

    constructor(serverUrl: String) {
        this.serverUrl = serverUrl
        this.httpClient = OkHttpClient.Builder()
            .connectTimeout(3, TimeUnit.MINUTES)
            .readTimeout(3, TimeUnit.MINUTES)
            .writeTimeout(3, TimeUnit.MINUTES)
            .callTimeout(4, TimeUnit.MINUTES)
            .addInterceptor(
                HttpLoggingInterceptor().apply {
                    level = HttpLoggingInterceptor.Level.BODY
                }
            )
            .build()
    }

    /**
     * Executes the API call to the PHP backend with dynamic data.
     */
    @Throws(IOException::class)
    fun getRawResponse(
        encryptedBundle: ByteArray,
        jpegImage: ByteArray?,
        // --- CHANGE 1: Accept dynamic data as parameters ---
        authToken: String,
        templateId: String,
        verificationId: String
    ): String {
        val request = buildApiRequest(encryptedBundle, jpegImage, authToken, templateId, verificationId)
        val response = httpClient.newCall(request).execute()

        if (!response.isSuccessful) {
            throwResponseError(response)
        }
        
        val responseBody = response.body?.string()
        if (responseBody == null) {
            throw IOException("Request was successful but the response body was empty.")
        }
        
        return responseBody
    }

    /**
     * Builds the multipart/form-data request using dynamic data.
     */
    private fun buildApiRequest(
        bundleData: ByteArray,
        jpegImageData: ByteArray?,
        // --- CHANGE 2: Accept dynamic data as parameters ---
        authToken: String,
        templateId: String,
        verificationId: String
    ): Request {
        val endpointUrl = "$serverUrl/biometricsverification"
        
        val bundleFileBody = bundleData.toRequestBody("application/octet-stream".toMediaType())
        
        val requestBodyBuilder = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("image", "capture.bin", bundleFileBody)
            // Use the dynamic data passed into the function
            .addFormDataPart("template_id", templateId)
            .addFormDataPart("verification_id", verificationId)

        jpegImageData?.let {
             val imageBase64 = Base64.encodeToString(it, Base64.NO_WRAP)
   
            val imageDataUri = "data:image/jpeg;base64,$imageBase64"
            requestBodyBuilder.addFormDataPart("image_base64", imageDataUri)
        }
            
        val requestBody = requestBodyBuilder.build()
            
        // --- CHANGE 3: Hardcoded values are removed. We use the parameters. ---

        return Request.Builder()
            .url(endpointUrl)
            .header("Authorization", "$authToken")
            .header("Accept", "application/json")
            .post(requestBody)
            .build()
    }

    @Throws(IOException::class)
    private fun throwResponseError(response: Response) {
        val errorBody = response.body?.string()
        if (errorBody == null) { throw IOException("Request failed with code ${response.code} and an empty error body.") }
        try {
            val jsonBody = JSONObject(errorBody)
            val message = jsonBody.optString("message", "An unknown error occurred.")
            throw IOException("Request failed: $message (Code: ${response.code})")
        } catch (e: Exception) {
            throw IOException("Request failed with code ${response.code}: $errorBody")
        }
    }

    companion object {
        private val TAG = DefIadWithFaceLivenessCheckClient::class.simpleName
    }
}

