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
                    // LEVEL.BODY is good for debugging, but ensure you check logs for "Authorization" header
                    level = HttpLoggingInterceptor.Level.BODY
                }
            )
            .build()
    }

    @Throws(IOException::class)
    fun getRawResponse(
        encryptedBundle: ByteArray,
        jpegImage: ByteArray?,
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

private fun buildApiRequest(
        bundleData: ByteArray,
        jpegImageData: ByteArray?,
        authToken: String,
        templateId: String,
        verificationId: String
    ): Request {
        val endpointUrl = "$serverUrl/biometricsverification"
        
        val bundleFileBody = bundleData.toRequestBody("application/octet-stream".toMediaType())
        
        val requestBodyBuilder = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("image", "capture.bin", bundleFileBody)
            .addFormDataPart("template_id", templateId)
            .addFormDataPart("verification_id", verificationId)

        jpegImageData?.let {
            val imageBase64 = Base64.encodeToString(it, Base64.NO_WRAP)
            val imageDataUri = "data:image/jpeg;base64,${imageBase64.trim()}"
            requestBodyBuilder.addFormDataPart("image_base64", imageDataUri)
        }
            
        val requestBody = requestBodyBuilder.build()

        // 1. Clean the input token
        var cleanToken = authToken.trim()
        
        // 2. Add Bearer if missing
        if (!cleanToken.startsWith("Bearer ", ignoreCase = true)) {
            cleanToken = "Bearer $cleanToken"
        }

        // Optional: Log it to be sure (remove before release)
        android.util.Log.d(TAG, "Sending Authorization: $cleanToken")

        return Request.Builder()
            .url(endpointUrl)
            // --- FIX IS HERE: Use 'cleanToken', not 'finalToken' ---
            .header("Authorization", cleanToken) 
            .header("Accept", "application/json")
            .post(requestBody)
            .build()
    }
    
    @Throws(IOException::class)
    private fun throwResponseError(response: Response) {
        val errorBody = response.body?.string()
        if (errorBody == null) { throw IOException("Request failed with code ${response.code} (Empty Body)") }
        
        // Log the error body to Logcat so you can see exactly why the server rejected it
        android.util.Log.e("IadClient", "Server Error: $errorBody")
        
        try {
            val jsonBody = JSONObject(errorBody)
            val message = jsonBody.optString("message", "An unknown error occurred.")
            throw IOException("$message (Code: ${response.code})")
        } catch (e: Exception) {
            throw IOException("Request failed with code ${response.code}: $errorBody")
        }
    }

    companion object {
        private val TAG = DefIadWithFaceLivenessCheckClient::class.simpleName
    }
}