import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../modal/settings.dart';
import 'package:http_parser/http_parser.dart';

/// A utility class that centralizes all API endpoint URLs for the application.
///
/// This class uses static constants and methods to provide a single, consistent
/// source for all network request URLs, making them easier to manage and update.
class ApiEndpoints {
  /// The base URL for all API requests.
  static const String baseUrl = 'https://integrate.idmetagroup.com/api';

  // --- Endpoint Definitions ---
  // The following static getters and constants define the specific paths for each API call.

  /// Endpoint to fetch UI design settings for a given template.
  static String getDesignSettings(String templateId) => '$baseUrl/user/api-trust-flow/get-design-settings/$templateId';

  /// Endpoint to create a new verification session.
  static const String createVerification = '$baseUrl/v1/verification/create-verification';

  /// Endpoint for document verification (image upload).
  static const String docVerification = '$baseUrl/v1/verification/document_verification';

  /// Endpoint to finalize a verification session.
  static const String finalizeVerification = '$baseUrl/v1/verification/finalize-verification';

  /// Endpoint for biometric user registration.
  static const String biometricRegistration = '$baseUrl/v1/verification/biometricsregistration';

  /// Endpoint for biometric user verification.
  static const String biometricVerification = '$baseUrl/v1/verification/biometricsverification';

  /// Endpoint for comparing two faces.
  static const String faceCompare = '$baseUrl/v1/verification/biometricsfacecompare';

  /// Endpoint for Anti-Money Laundering (AML) checks.
  static const String amlVerification = '$baseUrl/v1/verification/aml';

  /// Endpoint for Dukcapil (Indonesian population registry) verification.
  static const String dukcapilVerification = '$baseUrl/v1/verification/dukcapil';

  /// Endpoint for Dukcapil verification with a face match.
  static const String dukcapilFaceMatch = '$baseUrl/v1/verification/dukcapilfacematch';

  /// Endpoint for Philippines driving license verification.
  static const String philippinesDrivingLicense = '$baseUrl/v1/verification/philippines/drivinglicense';

  /// Endpoint for Philippines social security verification.
  static const String philippinesSocialSecurity = '$baseUrl/v1/verification/philippines/socialsecurity';

  /// Endpoint for Australian passport verification.
  static const String australiaPassport = '$baseUrl/v1/verification/australia/passport';

  /// Endpoint for QR code verification.
  static const String qrVerification = '$baseUrl/v1/verification/qr_code_verification';

  /// Endpoint to send an SMS OTP.
  static const String smsSend = '$baseUrl/v1/verification/sms-verification/send';

  /// Endpoint to verify an SMS OTP.
  static const String smsVerify = '$baseUrl/v1/verification/sms-verification/verify';

  /// Endpoint for Philippines PRC license verification.
  static const String philippinesPrc = '$baseUrl/v1/verification/philippines/prc';

  /// Endpoint to send an email OTP.
  static const String emailSend = '$baseUrl/v1/verification/email-verification/send';

  /// Endpoint to verify an email OTP.
  static const String emailVerify = '$baseUrl/v1/verification/email-verification/verify';

  /// Endpoint for custom document uploads.
  static const String customDocument = '$baseUrl/v1/verification/customdocument';

  /// Endpoint for Philippines NBI clearance verification.
  static const String philippinesNbiClearance = '$baseUrl/v1/verification/philippines/nbiclearance';

  /// Endpoint for Philippines national police clearance verification.
  static const String philippinesNationalPolice = '$baseUrl/v1/verification/philippines/nationalpolice';

  /// Endpoint for voice liveness verification.
  static const String voiceLiveness = '$baseUrl/v1/verification/biometrics/voiceliveness';

  /// Endpoint for business AML checks.
  static const String businessAml = '$baseUrl/v2/verification/business_aml';

  /// Endpoint for Finlink verification.
  static const String finlink = '$baseUrl/v2/verification/finlink';

  /// Endpoint for KTP (Indonesian ID card) details extraction.
  static const String ktpExtraction = '$baseUrl/v2/verification/ktp-extraction';

  /// Endpoint for comprehensive KYB (Know Your Business) checks.
  static const String kybComprehensive = '$baseUrl/v2/kyb/comprehensive';

  /// Endpoint for email social insights.
  static const String emailSocial = '$baseUrl/v2/email-social';

  /// Endpoint for phone social insights.
  static const String phoneSocial = '$baseUrl/v2/phone-social';

  /// Endpoint for submitting data from a dynamic custom form.
  static const String customForm = '$baseUrl/v2/verification/custom_form';

  /// Endpoint for fetching philsys validation.
  static String philsysPublicKey(String verificationId) => '$baseUrl/v2/philsys/validate-verification?verificationId=$verificationId';

  /// Endpoint for PhilSys (Philippine Identification System) verification.
  static const String philsys = '$baseUrl/v1/verification/philippines/philsys';
  static const String australiaImmigration = '$baseUrl/v1/verification/australia/immigration';
  static const String australiaCitizenCert = '$baseUrl/v1/verification/australia/certificate/citizenship';
  static const String australiaBirthCert = '$baseUrl/v1/verification/australia/certificate/birth';
  static const String australiaDeathCert = '$baseUrl/v1/verification/australia/certificate/death';
  static const String australiaAec = '$baseUrl/v1/verification/australia/aec';
  static const String australiaAsicMsic = '$baseUrl/v1/verification/australia/asic_msic';
  static const String australiaDl = '$baseUrl/v1/verification/australia/driver_license';
  static const String australiaVisa = '$baseUrl/v1/verification/australia/visa';
  static const String australiaMedicare = '$baseUrl/v1/verification/australia/medicare';
  static const String australiaCentrelink = '$baseUrl/v1/verification/australia/centrelink_card';
  static const String australiaConc = '$baseUrl/v1/verification/australia/certificate/changeOfName';
  static const String australiaMarriageCert = '$baseUrl/v1/verification/australia/certificate/marriage';
}

/// A custom exception class for handling API-related errors.
///
/// This allows for more specific error handling in the application, distinguishing
/// API failures from other types of exceptions.
class ApiException implements Exception {
  /// A user-friendly error message.
  final String message;

  /// The HTTP status code of the failed request, if available.
  final int? statusCode;

  /// Creates an [ApiException].
  ApiException(this.message, {this.statusCode});

  /// Provides a formatted string representation of the exception.
  @override
  String toString() => 'API Error: $message (Status Code: $statusCode)';
}

/// A service class responsible for all communication with the backend API.
///
/// It encapsulates the logic for making HTTP requests (GET, POST with JSON or multipart/form-data),
/// handling authorization, parsing responses, and managing errors.
class ApiService {
  /// The underlying HTTP client used for all requests.
  final http.Client _client;

  /// Creates an [ApiService]. An optional [http.Client] can be provided for testing purposes.
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// A generic helper method for sending `multipart/form-data` POST requests.
  ///
  /// This method handles request setup, authorization headers, sending data and files,
  /// timeout management, and response parsing, including detailed error handling.
  ///
  /// - Throws [ApiException] for network issues, timeouts, or server-side errors.
  /// - It includes special logic to handle a known "successful failure" case where a biometric
  ///   registration fails because the user already exists, which is treated as a success.
  Future<Map<String, dynamic>> _sendMultipartRequest(
    String endpoint, {
    required String userToken,
    required Map<String, String> fields,
    List<http.MultipartFile>? files,
  }) async {
    final url = Uri.parse(endpoint);
    final request = http.MultipartRequest('POST', url)
      ..headers['accept'] = 'application/json'
      ..headers['authorization'] = userToken.startsWith('Bearer ') ? userToken : 'Bearer $userToken'
      ..fields.addAll(fields);
    if (files != null) request.files.addAll(files);

    try {
      final response = await _client.send(request).timeout(const Duration(seconds: 90));
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Check for logical failures within a 2xx response.
        final bool isLogicalFailure = jsonResponse['status'] == false || (jsonResponse['result']?['status'] == 'failed');
        final errorMessage = jsonResponse['result']?['message'] ?? jsonResponse['message'] ?? 'Verification failed';

        if (isLogicalFailure) {
          // Special case: If registration fails because the user already exists,
          // we don't treat it as a critical error.
          final isRegistrationDuplicate = endpoint.contains(ApiEndpoints.biometricRegistration) &&
              (errorMessage.contains('Account already exists') || errorMessage.contains('already registered'));

          if (!isRegistrationDuplicate) {
            throw ApiException(errorMessage, statusCode: response.statusCode);
          }

          debugPrint("Handled known case: Biometric account already exists. Treating as success.");
        }
        return jsonResponse;
      } else {
        throw ApiException(
          jsonResponse['message'] ?? 'An unknown API error occurred.',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No Internet connection.');
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  /// A generic helper method for sending `application/json` POST requests.
  ///
  /// Similar to [_sendMultipartRequest], it handles the entire request lifecycle.
  /// Throws [ApiException] on failure.
  Future<Map<String, dynamic>> _sendJsonRequest(String endpoint, {required String userToken, required Map<String, dynamic> body}) async {
    final url = Uri.parse(endpoint);
    final headers = {
      'accept': 'application/json',
      'authorization': userToken.startsWith('Bearer ') ? userToken : 'Bearer $userToken',
      'Content-Type': 'application/json',
    };
    try {
      final response = await _client.post(url, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 90));
      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (jsonResponse['status'] == false || (jsonResponse['result']?['status'] == 'failed')) {
          throw ApiException(jsonResponse['message'] ?? jsonResponse['result']?['message'] ?? 'Verification failed', statusCode: response.statusCode);
        }
        return jsonResponse;
      } else {
        throw ApiException(jsonResponse['message'] ?? 'An unknown API error occurred.', statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('No Internet connection.');
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  // [NOTE: Most of the following methods are wrappers around the generic helper methods.]
  // [Their documentation is kept concise as the core logic is in the helpers.]

  /// Fetches the UI design settings for a given verification template.
  Future<DesignSettings> getDesignSettings({required String templateId}) async {
    final url = Uri.parse(ApiEndpoints.getDesignSettings(templateId));
    try {
      final response = await _client.get(url, headers: {'accept': 'application/json'}).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return DesignSettings.fromJson(jsonDecode(response.body));
      } else {
        throw ApiException('Failed to load design settings', statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('No Internet connection.');
    } on TimeoutException {
      throw ApiException('The request timed out. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: $e');
    }
  }

  /// Creates a new verification session on the backend.
  Future<Map<String, dynamic>> createVerification({required String userToken, required String templateId}) async {
    return _sendMultipartRequest(ApiEndpoints.createVerification, userToken: userToken, fields: {'template_id': templateId});
  }

  /// Finalizes the current verification session.
  Future<Map<String, dynamic>> finalizeVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
  }) async {
    return _sendMultipartRequest(
      ApiEndpoints.finalizeVerification,
      userToken: userToken,
      fields: {
        'template_id': templateId,
        'verification_id': verificationId,
      },
    );
  }

  /// Submits document images for analysis and data extraction.
  Future<Map<String, dynamic>> documentVerification(
      {required String userToken, required String templateId, required String verificationId, required File imageFile1, File? imageFile2}) async {
    final files = [await http.MultipartFile.fromPath('imageFrontSide', imageFile1.path)];
    if (imageFile2 != null) {
      files.add(await http.MultipartFile.fromPath('imageBackSide', imageFile2.path));
    }
    return _sendMultipartRequest(ApiEndpoints.docVerification,
        userToken: userToken, fields: {'template_id': templateId, 'verification_id': verificationId}, files: files);
  }

  /// Submits user details for an AML check against various datasets.
  Future<Map<String, dynamic>> amlVerification({
    required String userToken,
    required String verificationId,
    required String name,
    String? dob,
    String? gender,
    String? threshold,
  }) async {
    final body = <String, dynamic>{
      'verification_id': verificationId,
      'name': name,
      'datasets': ['PEP', 'SAN', 'RRE', 'INS', 'DD', 'POI', 'REL'],
      'countries': ['ID', 'PL', 'MY', 'US', 'AU', 'SG'],
    };
    if (dob != null && dob.isNotEmpty) body['dob'] = dob;
    if (gender != null && gender.isNotEmpty) body['gender'] = gender;

    if (threshold != null) {
      body['threshold'] = threshold;
    }

    return _sendJsonRequest(ApiEndpoints.amlVerification, userToken: userToken, body: body);
  }

  /// Registers a new user for biometric verification.
  Future<Map<String, dynamic>> biometricRegistration(
      {required String userToken, required String templateId, required String verificationId, required String username, required XFile imageFile}) async {
    return _sendMultipartRequest(ApiEndpoints.biometricRegistration,
        userToken: userToken,
        fields: {'username': username, 'template_id': templateId, 'verification_id': verificationId},
        files: [await http.MultipartFile.fromPath('image', imageFile.path)]);
  }

  /// Verifies a user against their registered biometric data.
  Future<Map<String, dynamic>> biometricVerification(
      {required String userToken, required String templateId, required String verificationId, required XFile imageFile}) async {
    return _sendMultipartRequest(ApiEndpoints.biometricVerification,
        userToken: userToken,
        fields: {'template_id': templateId, 'verification_id': verificationId},
        files: [await http.MultipartFile.fromPath('image', imageFile.path)]);
  }

  /// Compares two facial images for similarity.
  Future<Map<String, dynamic>> faceCompare(
      {required String userToken,
      required String templateId,
      required String verificationId,
      required XFile imageFile1,
      XFile? imageFile2,
      Uint8List? imageFile2Bytes}) async {
    final files = [await http.MultipartFile.fromPath('image1', imageFile1.path)];
    if (imageFile2 != null) {
      files.add(await http.MultipartFile.fromPath('image2', imageFile2.path));
    } else if (imageFile2Bytes != null) {
      files.add(http.MultipartFile.fromBytes('image2', imageFile2Bytes, filename: 'image2.jpeg'));
    }
    return _sendMultipartRequest(ApiEndpoints.faceCompare,
        userToken: userToken, fields: {'template_id': templateId, 'verification_id': verificationId}, files: files);
  }

  // [The remaining methods follow the established patterns and are self-documenting by their names and parameters.]
  // [Adding full doc comments to each of the ~50 methods would be highly redundant.]

  Future<Map<String, dynamic>> dukcapilVerification(
      {required String userToken,
      required String verificationId,
      required String name,
      required String dob,
      required String nik,
      required String templateId}) async {
    return _sendJsonRequest(ApiEndpoints.dukcapilVerification,
        userToken: userToken, body: {"name": name, "date_of_birth": dob, "nik": nik, "template_id": templateId, "verification_id": verificationId});
  }

  Future<Map<String, dynamic>> dukcapilFaceMatch({
    required String userToken,
    required String verificationId,
    required String name,
    required String dob,
    required String nik,
    required File imageFile,
    required String templateId,
  }) async {
    final String base64Image = base64Encode(await imageFile.readAsBytes());
    return _sendMultipartRequest(
      ApiEndpoints.dukcapilFaceMatch,
      userToken: userToken,
      fields: {
        'template_id': templateId,
        'verification_id': verificationId,
        'nik': nik,
        'name': name,
        'date_of_birth': dob,
        'selfie_image': base64Image,
      },
      files: [],
    );
  }

  Future<Map<String, dynamic>> philippinesDrivingLicense(
      {required String userToken,
      required String verificationId,
      required String licenseNumber,
      required String expiryDate,
      required String serialNumber,
      required String templateId}) async {
    return _sendJsonRequest(ApiEndpoints.philippinesDrivingLicense, userToken: userToken, body: {
      "template_id": templateId,
      "verification_id": verificationId,
      "licenseNumber": licenseNumber,
      "expirationDate": expiryDate,
      "serialNumber": serialNumber,
    });
  }

  Future<Map<String, dynamic>> philippinesSocialSecurity(
      {required String userToken, required String verificationId, required String sssNumber, required String templateId}) async {
    return _sendJsonRequest(ApiEndpoints.philippinesSocialSecurity, userToken: userToken, body: {
      "template_id": templateId,
      "verification_id": verificationId,
      "crnSsNumber": sssNumber,
    });
  }

  Future<Map<String, dynamic>> australiaPassport(
      {required String userToken,
      required String verificationId,
      required String lastName,
      required String givenName,
      required String dob,
      required String gender,
      required String passportNumber,
      required String templateId}) async {
    return _sendJsonRequest(ApiEndpoints.australiaPassport, userToken: userToken, body: {
      "family_name": lastName,
      "given_name": givenName,
      "dob": dob,
      "gender": gender,
      "travel_document_number": passportNumber,
      "template_id": templateId,
      "verification_id": verificationId
    });
  }

  /// A generic helper method for sending `application/x-www-form-urlencoded` POST requests.
  Future<Map<String, dynamic>> _sendUrlEncodedRequest(
    String endpoint, {
    required String userToken,
    required Map<String, String> body,
  }) async {
    final url = Uri.parse(endpoint);
    final headers = {
      'accept': 'application/json',
      'authorization': userToken.startsWith('Bearer ') ? userToken : 'Bearer $userToken',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    try {
      final response = await _client.post(url, headers: headers, body: body).timeout(const Duration(seconds: 90));
      final jsonResponse = jsonDecode(response.body);

      return jsonResponse;
    } on SocketException {
      throw ApiException('No Internet connection.');
    }
  }

  /// Submits data from a QR code for verification.
  Future<Map<String, dynamic>> verifyQrCode({
    required String userToken,
    required String templateId,
    required String verificationId,
    required Map<String, dynamic> qrPayload,
  }) async {
    // Helper to ensure all values in the payload are strings for URL encoding.
    Map<String, String> _flattenMap(Map<String, dynamic> map) {
      final flatMap = <String, String>{};
      map.forEach((key, value) {
        flatMap[key] = value.toString();
      });
      return flatMap;
    }

    final Map<String, String> body = _flattenMap(qrPayload);
    body['template_id'] = templateId;
    body['verification_id'] = verificationId;

    return _sendUrlEncodedRequest(
      ApiEndpoints.qrVerification,
      userToken: userToken,
      body: body,
    );
  }

  /// Sends an OTP code via SMS.
  Future<Map<String, dynamic>> smsSendOtp({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String phoneNumber,
    required String countryCode,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.smsSend,
      userToken: userToken,
      body: {
        "phone_number": phoneNumber,
        "country_code": countryCode,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Verifies an OTP code received via SMS.
  Future<Map<String, dynamic>> smsVerifyOtp({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String otp,
    required String referenceId,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.smsVerify,
      userToken: userToken,
      body: {
        "otp": otp,
        "ref_id": referenceId,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Verifies a Philippines PRC license.
  Future<Map<String, dynamic>> phPrcVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String profession,
    String? firstName,
    String? lastName,
    String? licenseNo,
    String? dateOfBirth,
  }) async {
    final body = <String, dynamic>{
      "template_id": templateId,
      "verification_id": verificationId,
      "profession": profession,
    };

    if (firstName != null && lastName != null) {
      body["firstName"] = firstName;
      body["lastName"] = lastName;
    } else if (licenseNo != null && dateOfBirth != null) {
      body["licenseNo"] = licenseNo;
      body["dateOfBirth"] = dateOfBirth;
    }

    return _sendJsonRequest(
      ApiEndpoints.philippinesPrc,
      userToken: userToken,
      body: body,
    );
  }

  /// Sends an OTP code via email.
  Future<Map<String, dynamic>> emailSendOtp({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String email,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.emailSend,
      userToken: userToken,
      body: {
        "email": email,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Verifies an OTP code received via email.
  Future<Map<String, dynamic>> emailVerifyOtp({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String otp,
    required String referenceId,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.emailVerify,
      userToken: userToken,
      body: {
        "otp": otp,
        "ref_id": referenceId,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits a generic document file for a custom verification process.
  Future<Map<String, dynamic>> customDocumentVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required File documentFile,
  }) async {
    return _sendMultipartRequest(ApiEndpoints.customDocument, userToken: userToken, fields: {
      "template_id": templateId,
      "verification_id": verificationId,
    }, files: [
      await http.MultipartFile.fromPath('document', documentFile.path)
    ]);
  }

  /// Verifies a Philippines NBI clearance number.
  Future<Map<String, dynamic>> phNbiClearance({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String clearanceNo,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.philippinesNbiClearance,
      userToken: userToken,
      body: {
        "template_id": templateId,
        "verification_id": verificationId,
        "clearanceNo": clearanceNo,
      },
    );
  }

  /// Verifies a Philippines national police clearance number.
  Future<Map<String, dynamic>> phNationalPolice({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String surname,
    required String clearanceNo,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.philippinesNationalPolice,
      userToken: userToken,
      body: {
        "template_id": templateId,
        "verification_id": verificationId,
        "surname": surname,
        "clearanceNo": clearanceNo,
      },
    );
  }

  /// Submits a voice recording for liveness detection.
  Future<Map<String, dynamic>> voiceLivenessVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required File audioFile,
  }) async {
    return _sendMultipartRequest(ApiEndpoints.voiceLiveness, userToken: userToken, fields: {
      "template_id": templateId,
      "verification_id": verificationId,
    }, files: [
      await http.MultipartFile.fromPath('audio', audioFile.path, contentType: MediaType('audio', 'wav')),
    ]);
  }

  /// Submits a business name for an AML check.
  Future<Map<String, dynamic>> businessAmlVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String businessName,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.businessAml,
      userToken: userToken,
      body: {
        "name": businessName,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits form data for Finlink verification.
  Future<Map<String, dynamic>> finlinkVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required Map<String, dynamic> formData,
  }) async {
    final body = Map<String, dynamic>.from(formData);
    body['template_id'] = templateId;
    body['verification_id'] = verificationId;

    return _sendJsonRequest(
      ApiEndpoints.finlink,
      userToken: userToken,
      body: body,
    );
  }

  /// Submits an image of a KTP for data extraction.
  Future<Map<String, dynamic>> ktpDetailsExtraction({
    required String userToken,
    required String templateId,
    required String verificationId,
    required File imageFile,
  }) async {
    return _sendMultipartRequest(ApiEndpoints.ktpExtraction, userToken: userToken, fields: {
      "template_id": templateId,
      "verification_id": verificationId,
    }, files: [
      await http.MultipartFile.fromPath('imageFrontSide', imageFile.path)
    ]);
  }

  /// Submits company details for a comprehensive KYB check.
  Future<Map<String, dynamic>> kybComprehensiveVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String companyName,
    required String countryCode,
    required String registrationNumber,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.kybComprehensive,
      userToken: userToken,
      body: {
        "companyName": companyName,
        "country": countryCode,
        "registrationNumber": registrationNumber,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits an email address to gather social media and other online insights.
  Future<Map<String, dynamic>> emailSocialInsight({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String email,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.emailSocial,
      userToken: userToken,
      body: {
        "email": email,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits a phone number to gather social media and other online insights.
  Future<Map<String, dynamic>> phoneSocialInsight({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String phoneNumber,
    required String countryCode,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.phoneSocial,
      userToken: userToken,
      body: {
        "phone_number": phoneNumber,
        "country_code": countryCode,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data from a dynamically generated form, handling both text and file inputs.
  Future<Map<String, dynamic>> submitCustomForm({
    required String userToken,
    required String templateId,
    required String verificationId,
    required Map<String, dynamic> formData,
  }) async {
    final fields = <String, String>{
      'template_id': templateId,
      'verification_id': verificationId,
    };
    final files = <http.MultipartFile>[];

    // Separate text fields from file fields for the multipart request.
    for (final entry in formData.entries) {
      if (entry.value is File) {
        files.add(await http.MultipartFile.fromPath(entry.key, (entry.value as File).path));
      } else if (entry.value != null) {
        fields[entry.key] = entry.value.toString();
      }
    }

    return _sendMultipartRequest(
      ApiEndpoints.customForm,
      userToken: userToken,
      fields: fields,
      files: files,
    );
  }

  /// Submits data for PhilSys verification.
  Future<Map<String, dynamic>> philsysVerification({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String faceLivenessSessionId,
    String? qrData,
    String? pcn,
    Map<String, dynamic>? pcnFormData,
  }) async {
    final body = <String, dynamic>{
      'face_liveness_session_id': faceLivenessSessionId,
      'template_id': templateId,
      'verification_id': verificationId,
    };

    if (qrData != null) body['qr_data'] = qrData;
    if (pcn != null) body['pcn'] = pcn;
    if (pcnFormData != null) body['pcnFormData'] = pcnFormData;

    return _sendJsonRequest(
      ApiEndpoints.philsys,
      userToken: userToken,
      body: body,
    );
  }

  Future<String> fetchPublicKey({
    required String userToken,
    required String verificationId,
  }) async {
    final url = Uri.parse(ApiEndpoints.philsysPublicKey(verificationId));
    final headers = {
      'Authorization': userToken.startsWith('Bearer ') ? userToken : 'Bearer $userToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    try {
      final response = await _client.get(url, headers: headers).timeout(const Duration(seconds: 30));
      final jsonResponse = jsonDecode(response.body);
      print(jsonResponse);
      if (response.statusCode == 200) {
        if (jsonResponse['status'] == 'SUCCESS' && jsonResponse['publicKey'] != null) {
          return jsonResponse['publicKey'] as String;
        }
        throw ApiException(jsonResponse['message'] ?? 'Invalid response for public key.', statusCode: 200);
      } else {
        throw ApiException('API Connection Failed.', statusCode: response.statusCode);
      }
    } on SocketException {
      throw ApiException('No Internet connection.');
    } on TimeoutException {
      throw ApiException('The request for the public key timed out.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred while fetching the public key: $e');
    }
  }

  /// Submits data for Australian immigration card verification.
  Future<Map<String, dynamic>> australiaImmigration({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String familyName,
    required String givenName,
    required String dob,
    required String immigrationCardNumber,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaImmigration,
      userToken: userToken,
      body: {
        "family_name": familyName,
        "given_name": givenName,
        "dob": dob,
        "immigration_card_number": immigrationCardNumber,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian citizenship certificate verification.
  Future<Map<String, dynamic>> australiaCitizenCert({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String familyName,
    String? givenName,
    required String dob,
    required String acquisitionDate,
    required String stockNumber,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaCitizenCert,
      userToken: userToken,
      body: {
        "family_name": familyName,
        "given_name": givenName,
        "dob": dob,
        "acquisition_date": acquisitionDate,
        "stock_number": stockNumber,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian birth certificate verification.
  Future<Map<String, dynamic>> australiaBirthCert({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String familyName,
    required String givenName,
    required String dob,
    required String registrationNumber,
    required String registrationState,
    String? registrationDate,
    String? certificateNumber,
    String? datePrinted,
    String? registrationYear,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaBirthCert,
      userToken: userToken,
      body: {
        "family_name": familyName,
        "given_name": givenName,
        "dob": dob,
        "registration_number": registrationNumber,
        "registration_state": registrationState,
        "registration_date": registrationDate,
        "certificate_number": certificateNumber,
        "date_printed": datePrinted,
        "registration_year": registrationYear,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian death certificate verification.
  Future<Map<String, dynamic>> australiaDeathCert({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String familyName,
    required String givenName,
    required String doe, // date of event
    required String registrationNumber,
    required String registrationState,
    required String registrationDate,
    required String certificateNumber,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaDeathCert,
      userToken: userToken,
      body: {
        "family_name": familyName,
        "given_name": givenName,
        "doe": doe,
        "registration_number": registrationNumber,
        "registration_state": registrationState,
        "registration_date": registrationDate,
        "certificate_number": certificateNumber,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian Electoral Commission (AEC) verification.
  Future<Map<String, dynamic>> australiaAec({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String familyName,
    required String givenName,
    String? dob,
    required String suburb,
    required String postcode,
    required String state,
    String? streetName,
    String? streetType,
    String? streetNumber,
    String? unitNumber,
    String? habitationName,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaAec,
      userToken: userToken,
      body: {
        "family_name": familyName,
        "given_name": givenName,
        "dob": dob,
        "suburb": suburb,
        "postcode": postcode,
        "state": state,
        "street_name": streetName,
        "street_type": streetType,
        "street_number": streetNumber,
        "unit_number": unitNumber,
        "habitation_name": habitationName,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian ASIC/MSIC card verification.
  Future<Map<String, dynamic>> australiaAsicMsic({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String fullName,
    required String dob,
    required String cardNumber,
    required String cardExpiry,
    required String cardType,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaAsicMsic,
      userToken: userToken,
      body: {
        "full_name": fullName,
        "dob": dob,
        "card_number": cardNumber,
        "card_expiry": cardExpiry,
        "card_type": cardType,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian driver's license verification.
  Future<Map<String, dynamic>> australiaDrivingLicense({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String familyName,
    String? middleName,
    required String givenName,
    required String dob,
    String? cardNumber,
    required String licenceNumber,
    required String stateOfIssue,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaDl,
      userToken: userToken,
      body: {
        "family_name": familyName,
        "middle_name": middleName,
        "given_name": givenName,
        "dob": dob,
        "card_number": cardNumber,
        "licence_number": licenceNumber,
        "state_of_issue": stateOfIssue,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits passport data for Australian visa verification.
  Future<Map<String, dynamic>> australiaVisa({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String familyName,
    required String givenName,
    required String dob,
    required String passportNumber,
    required String countryOfIssue,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaVisa,
      userToken: userToken,
      body: {
        "family_name": familyName,
        "given_name": givenName,
        "dob": dob,
        "passport_number": passportNumber,
        "country_of_issue": countryOfIssue,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian Medicare card verification.
  Future<Map<String, dynamic>> australiaMedicare({
    required String userToken,
    required String templateId,
    required String verificationId,
    String? name1,
    String? name2,
    String? name3,
    String? name4,
    required String cardExpiry,
    required String cardNumber,
    required String cardType,
    required String individualReferenceNumber,
    String? dob,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaMedicare,
      userToken: userToken,
      body: {
        "name1": name1,
        "name2": name2,
        "name3": name3,
        "name4": name4,
        "card_expiry": cardExpiry,
        "card_number": cardNumber,
        "card_type": cardType,
        "individual_reference_number": individualReferenceNumber,
        "dob": dob,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian Centrelink card verification.
  Future<Map<String, dynamic>> australiaCentrelink({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String name,
    required String dob,
    required String cardExpiry,
    required String cardType,
    required String customerReferenceNumber,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaCentrelink,
      userToken: userToken,
      body: {
        "name": name,
        "dob": dob,
        "card_expiry": cardExpiry,
        "card_type": cardType,
        "customer_reference_number": customerReferenceNumber,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian change of name certificate verification.
  Future<Map<String, dynamic>> australiaChangeOfNameCert({
    required String userToken,
    required String templateId,
    required String verificationId,
    String? familyName,
    String? givenName,
    required String newFamilyName,
    required String newGivenName,
    required String dob,
    required String registrationNumber,
    required String registrationState,
    String? registrationDate,
    String? certificateNumber,
    String? datePrinted,
    String? registrationYear,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaConc,
      userToken: userToken,
      body: {
        "family_name": familyName,
        "given_name": givenName,
        "new_family_name": newFamilyName,
        "new_given_name": newGivenName,
        "dob": dob,
        "registration_number": registrationNumber,
        "registration_state": registrationState,
        "registration_date": registrationDate,
        "certificate_number": certificateNumber,
        "date_printed": datePrinted,
        "registration_year": registrationYear,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }

  /// Submits data for Australian marriage certificate verification.
  Future<Map<String, dynamic>> australiaMarriageCert({
    required String userToken,
    required String templateId,
    required String verificationId,
    required String brideFamilyName,
    required String brideGivenName,
    required String groomFamilyName,
    required String groomGivenName,
    required String dob, // Assuming this is marriage date
    required String registrationNumber,
    required String registrationState,
    String? registrationDate,
    String? certificateNumber,
    String? datePrinted,
    String? registrationYear,
  }) async {
    return _sendJsonRequest(
      ApiEndpoints.australiaMarriageCert,
      userToken: userToken,
      body: {
        "bride_family_name": brideFamilyName,
        "bride_given_name": brideGivenName,
        "groom_family_name": groomFamilyName,
        "groom_given_name": groomGivenName,
        "dob": dob, // Labeled as "Date of Marriage" in UI
        "registration_number": registrationNumber,
        "registration_state": registrationState,
        "registration_date": registrationDate,
        "certificate_number": certificateNumber,
        "date_printed": datePrinted,
        "registration_year": registrationYear,
        "template_id": templateId,
        "verification_id": verificationId,
      },
    );
  }
}
