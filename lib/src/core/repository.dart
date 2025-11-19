import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../modal/flow_sate.dart';
import '../api/service.dart';

/// A repository class that encapsulates the business logic and state management for the verification flow.
///
/// This class acts as the single source of truth for the verification state ([VerificationFlowState]).
/// It serves as an intermediary between the UI-facing `Verification` provider and the network-level
/// `ApiService`. Its responsibilities include initiating the verification, submitting data for each step,
/// handling complex logic like automated sub-steps, and managing the navigation history of the flow.
class VerificationRepository {
  /// The service responsible for making direct network calls to the backend API.
  final ApiService _apiService;

  /// The private, mutable state of the verification flow.
  VerificationFlowState _flowState = VerificationFlowState.initial();

  /// The public, immutable getter for the current verification flow state.
  VerificationFlowState get flowState => _flowState;

  /// Creates a [VerificationRepository].
  VerificationRepository({required ApiService apiService}) : _apiService = apiService;

  /// Initializes the repository with the essential user and template identifiers.
  /// This must be called before any other methods.
  void initialize({required String userToken, required String templateId}) {
    _flowState = VerificationFlowState.initial().copyWith(userToken: userToken, templateId: templateId);
  }

  /// Kicks off the verification process by calling the create-verification endpoint.
  /// It then updates the internal state with the flow steps and settings received from the response.
  Future<void> startVerification() async {
    if (_flowState.userToken == null || _flowState.templateId == null) {
      throw Exception('Repository not initialized.');
    }
    final response = await _apiService.createVerification(userToken: _flowState.userToken!, templateId: _flowState.templateId!);
    _updateStateFromVerificationResponse(response);
  }

  /// Parses the JSON response from the `startVerification` call and updates the [VerificationFlowState].
  void _updateStateFromVerificationResponse(Map<String, dynamic> response) async {
    final verificationId = response['verification']?['id']?.toString();
    if (verificationId == null) throw ApiException('Verification ID not found in response.');

    // Extract the ordered list of verification steps (plans).
    List<String> plans = (response['plans'] as List? ?? []).map((p) => p['plan'].toString()).toList();
    // Extract the specific configurations for each tool/plan.
    Map<String, Map<String, dynamic>> toolSettings = {};
    if (response['tool_settings'] is List) {
      for (var setting in (response['tool_settings'] as List)) {
        if (setting is Map<String, dynamic> && setting['plan'] is String) {
          toolSettings[setting['plan']] = setting['config'] ?? {};
        }
      }
    }

    if (plans.contains('scan_qr')) {
      try {
        debugPrint("PhilSys plan detected. Fetching public key...");
        final publicKey = await _apiService.fetchPublicKey(
          userToken: _flowState.userToken!,
          verificationId: verificationId,
        );
        // Ensure the tool settings map for this plan exists
        toolSettings['scan_qr'] ??= {};
        // Add the fetched public key to the tool settings
        toolSettings['scan_qr']!['publicKey'] = publicKey;
        debugPrint("✅ Public key fetched and stored successfully.");
      } catch (e) {
        debugPrint("⚠️ Failed to fetch PhilSys public key: $e");
        // We let it continue, but the webview will show an error, which is correct.
      }
    }

    // Pre-process the steps to configure any automated checks.
    _handleAutomatedSteps(plans, toolSettings);

    // Update the state with the new flow configuration.
    _flowState = _flowState.copyWith(
      verificationId: verificationId,
      allSteps: plans,
      toolSettings: toolSettings,
      currentStepIndex: 0,
      history: [],
    );
  }

  /// A private helper to configure automated checks that can occur after document verification.
  ///
  /// It inspects the list of upcoming plans. If it finds a plan that can be automated
  /// using data from a document scan (e.g., 'aml', 'dukcapil'), it injects a special flag
  /// (e.g., `autoRunAml: true`) into the `document_verification` tool settings. This flag
  /// is later used by [_runAllAutomatedChecksPostDocument].
  void _handleAutomatedSteps(List<String> plans, Map<String, Map<String, dynamic>> toolSettings) {
    const autoCheckPlans = {
      'aml': 'autoRunAml',
      'dukcapil': 'autoRunDukcapil',
      'dukcapil_facematch': 'autoRunDukcapilFace',
      'philippines_driving_license': 'autoRunPhDriving',
      'philippines_social_security': 'autoRunPhSocialSecurity',
      'australia_passport': 'autoRunAustraliaPassport',
    };

    // This logic only applies if document verification is part of the flow.
    if (plans.contains('document_verification')) {
      for (final entry in autoCheckPlans.entries) {
        final planKey = entry.key;
        final configFlag = entry.value;
        if (plans.contains(planKey)) {
          // Add the auto-run flag to the document verification settings.
          toolSettings['document_verification'] = {...toolSettings['document_verification'] ?? {}, configFlag: true};
          debugPrint("Configuration found to automate '$planKey' step post-document verification.");
        }
      }
    }
  }

  /// Submits document images, updates the state with extracted data, and runs any configured automated checks.
  Future<void> submitDocument(File front, File? back) async {
    final response = await _apiService.documentVerification(
        userToken: _flowState.userToken!, templateId: _flowState.templateId!, verificationId: _flowState.verificationId!, imageFile1: front, imageFile2: back);

    _updateStateFromDocumentResponse(response);
    await _runAllAutomatedChecksPostDocument();
  }

  /// Parses the response from a document verification call and stores the extracted data.
  void _updateStateFromDocumentResponse(Map<String, dynamic> response) {
    final rawResult = response['result'];
    final isExtraction = rawResult?['data']?['extractionResult'] != null;
    final extractionResult = isExtraction ? rawResult['data']['extractionResult'] : rawResult['result'];

    if (extractionResult != null) {
      final newData = Map<String, dynamic>.from(_flowState.collectedData);

      // Helper to safely extract fields from different response structures.
      String? getField(String key) {
        if (isExtraction) return extractionResult[key]?['latin']?.toString();
        return extractionResult[key]?.toString();
      }

      // Populate collectedData with extracted information.
      newData['fullName'] = getField('fullName');
      newData['firstName'] = getField('firstName');
      newData['lastName'] = getField('lastName');
      newData['docNumber'] = getField('documentNumber');
      newData['sex'] = getField('sex');
      newData['profession'] = getField('profession');
      newData['faceImageBase64'] = extractionResult['faceImageBase64']?.toString();

      if (extractionResult['mrzData'] != null) {
        newData['mrzData'] = extractionResult['mrzData'];
      }

      // Safely parse date fields.
      final dob = extractionResult['dateOfBirth'];
      if (dob is Map && dob['year'] != null) {
        newData['dob'] = DateFormat('yyyy-MM-dd').format(DateTime(dob['year'], dob['month'], dob['day']));
      }
      final doe = extractionResult['dateOfExpiry'];
      if (doe is Map && doe['year'] != null) {
        newData['doe'] = DateFormat('yyyy-MM-dd').format(DateTime(doe['year'], doe['month'], doe['day']));
      }

      _flowState = _flowState.copyWith(collectedData: newData);
    }
  }

  /// This critical method attempts to run subsequent verification steps automatically
  /// using data extracted from a previously submitted document.
  ///
  /// It checks for the `autoRun...` flags (set by [_handleAutomatedSteps]) and uses
  /// the data in [_flowState.collectedData] to make the API calls. If an automated
  /// check is successful, that step is removed from the user's flow.
  Future<void> _runAllAutomatedChecksPostDocument() async {
    final docSettings = _flowState.toolSettings['document_verification'] ?? {};
    final data = _flowState.collectedData;
    List<String> plansToProcess = List.from(_flowState.allSteps);

    // --- Automated AML Check ---
    if (plansToProcess.contains('aml') && docSettings['autoRunAml'] == true) {
      final String? name = data['fullName'] ?? data['firstName'];
      if (name != null && name.isNotEmpty) {
        try {
          await submitAmlData(name: name, dob: data['dob'], gender: data['sex'] ?? 'any');
          debugPrint("✅ Automated AML check successful.");
          plansToProcess.remove('aml');
        } catch (e) {
          debugPrint("⚠️ Automated AML check failed: $e.");
        }
      }
    }

    // --- Automated Dukcapil Check ---
    if (plansToProcess.contains('dukcapil') && docSettings['autoRunDukcapil'] == true) {
      final String? name = data['fullName'] ?? data['firstName'];
      final String? nik = data['docNumber'];
      final String? dob = data['dob'];
      if (name != null && name.isNotEmpty && nik != null && dob != null && nik.length == 16) {
        try {
          await submitDukcapilData(name: name, nik: nik, dob: dob);
          debugPrint("✅ Automated Dukcapil check successful.");
          plansToProcess.remove('dukcapil');
        } catch (e) {
          debugPrint("⚠️ Automated Dukcapil check failed: $e.");
        }
      } else {
        debugPrint("⚠️ Invalid data for Dukcapil check.");
      }
    }

    if (plansToProcess.contains('dukcapil_facematch') && docSettings['autoRunDukcapilFace'] == true) {
      debugPrint("⚠️ Dukcapil Face Match cannot be automated post-document scan without a live selfie.");
    }

    // [NOTE: The following checks follow the same pattern as AML and Dukcapil.]

    if (plansToProcess.contains('philippines_driving_license') && docSettings['autoRunPhDriving'] == true) {
      final String? licenseNo = data['docNumber'];
      if (licenseNo != null && licenseNo.replaceAll("-", "").length == 11) {
        try {
          await submitPhDrivingLicenseData(licenseNumber: licenseNo, expiryDate: data['doe'] ?? "", serialNumber: "");
          debugPrint("✅ Automated PH Driving License check successful.");
          plansToProcess.remove('philippines_driving_license');
        } catch (e) {
          debugPrint("⚠️ Automated PH Driving License check failed: $e.");
        }
      } else {
        debugPrint("⚠️ Invalid format for PH Driving License.");
      }
    }

    if (plansToProcess.contains('philippines_social_security') && docSettings['autoRunPhSocialSecurity'] == true) {
      final String? sssNo = data['docNumber'];
      if (sssNo != null && sssNo.replaceAll("-", "").length == 10) {
        try {
          await submitPhSocialSecurityData(sssNumber: sssNo);
          debugPrint("✅ Automated PH Social Security check successful.");
          plansToProcess.remove('philippines_social_security');
        } catch (e) {
          debugPrint("⚠️ Automated PH Social Security check failed: $e.");
        }
      } else {
        debugPrint("⚠️ Invalid format for SSS number.");
      }
    }

    if (plansToProcess.contains('australia_passport') && docSettings['autoRunAustraliaPassport'] == true) {
      final mrzData = data['mrzData'] as Map<String, dynamic>?;
      if (mrzData != null && mrzData['documentType'] == 'PASSPORT') {
        try {
          await submitAuPassportData(
            lastName: data['lastName'] ?? "",
            givenName: data['firstName'] ?? "",
            dob: data['dob'] ?? "",
            gender: data['sex'] ?? "X",
            passportNumber: data['docNumber'] ?? "",
          );
          debugPrint("✅ Automated Australia Passport check successful.");
          plansToProcess.remove('australia_passport');
        } catch (e) {
          debugPrint("⚠️ Automated Australia Passport check failed: $e.");
        }
      } else {
        debugPrint("⚠️ Document is not a passport, skipping check.");
      }
    }

    debugPrint("Original plans: ${_flowState.allSteps}");
    debugPrint("Final remaining manual plans: $plansToProcess");

    // Update the state with the new, potentially shorter, list of steps.
    _flowState = _flowState.copyWith(allSteps: plansToProcess);
  }

  // --- Public Data Submission Methods ---
  // These methods act as a clean interface for the Verification provider to call.
  // They gather the necessary IDs from the current state and pass them to the ApiService.

  /// Submits the necessary data for AML verification.
  Future<void> submitAmlData({required String name, String? dob, String? gender}) async {
    final amlSettings = _flowState.toolSettings['aml'] ?? {};
    final threshold = amlSettings['threshold']?.toString();

    await _apiService.amlVerification(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      name: name,
      dob: dob,
      gender: gender,
      threshold: threshold,
    );
  }

  /// Submits images for face comparison.
  ///
  /// Special logic: If a face was extracted from a document (`faceImageBase64`) and
  /// no second manual image is provided, it uses the extracted face data as the
  /// second image for the comparison.
  Future<void> submitFaceCompare({required XFile liveSelfie, XFile? manualImage2}) async {
    final documentFaceBase64 = _flowState.collectedData['faceImageBase64'] as String?;
    Uint8List? documentFaceBytes;
    if (documentFaceBase64 != null && manualImage2 == null) {
      documentFaceBytes = base64Decode(documentFaceBase64);
    }
    await _apiService.faceCompare(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      imageFile1: liveSelfie,
      imageFile2: manualImage2,
      imageFile2Bytes: documentFaceBytes,
    );
  }

  // [NOTE: The remaining submission methods are straightforward wrappers around ApiService calls.]
  // [They are documented implicitly by their clear naming and parameter lists.]

  Future<void> submitBiometricVerification({required XFile image}) async {
    await _apiService.biometricVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      imageFile: image,
    );
  }

  Future<void> submitBiometricRegistration({required String username, required XFile image}) async {
    await _apiService.biometricRegistration(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      username: username,
      imageFile: image,
    );
  }

  Future<void> submitDukcapilData({required String name, required String dob, required String nik}) async {
    await _apiService.dukcapilVerification(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      name: name,
      dob: dob,
      nik: nik,
    );
  }

  Future<void> submitDukcapilFaceMatchData({required String name, required String dob, required String nik, required File image}) async {
    await _apiService.dukcapilFaceMatch(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      name: name,
      dob: dob,
      nik: nik,
      imageFile: image,
    );
  }

  Future<void> submitPhDrivingLicenseData({required String licenseNumber, required String expiryDate, required String serialNumber}) async {
    await _apiService.philippinesDrivingLicense(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      licenseNumber: licenseNumber,
      expiryDate: expiryDate,
      serialNumber: serialNumber,
    );
  }

  Future<void> submitPhSocialSecurityData({required String sssNumber}) async {
    await _apiService.philippinesSocialSecurity(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      sssNumber: sssNumber,
    );
  }

  Future<void> submitAuPassportData(
      {required String lastName, required String givenName, required String dob, required String gender, required String passportNumber}) async {
    await _apiService.australiaPassport(
      userToken: _flowState.userToken!,
      verificationId: _flowState.verificationId!,
      templateId: _flowState.templateId!,
      lastName: lastName,
      givenName: givenName,
      dob: dob,
      gender: gender,
      passportNumber: passportNumber,
    );
  }

  Future<void> submitQrCode({required Map<String, dynamic> qrPayload}) async {
    await _apiService.verifyQrCode(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      qrPayload: qrPayload,
    );
  }

  Future<void> submitPhPrcData({
    required String profession,
    String? firstName,
    String? lastName,
    String? licenseNo,
    String? dob,
  }) async {
    await _apiService.phPrcVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      profession: profession,
      firstName: firstName,
      lastName: lastName,
      licenseNo: licenseNo,
      dateOfBirth: dob,
    );
  }

  /// Sends an OTP to an email address and returns a reference ID for verification.
  Future<String> sendEmailOtp({required String email}) async {
    final response = await _apiService.emailSendOtp(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      email: email,
    );

    final referenceId = response['result']?['status']?['code']?.toString();
    if (referenceId == null) {
      throw ApiException("Could not get OTP from the server.", statusCode: 200);
    }
    return referenceId;
  }

  /// Verifies an email OTP using the provided code and reference ID.
  Future<void> verifyEmailOtp({required String otp, required String referenceId}) async {
    await _apiService.emailVerifyOtp(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      otp: otp,
      referenceId: referenceId,
    );
  }

  /// Sends an OTP to a phone number and returns a reference ID for verification.
  Future<String> sendSmsOtp({required String phoneNumber, required String countryCode}) async {
    final response = await _apiService.smsSendOtp(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
    );

    final referenceId = response['result']?['otp_result']?['reference_id'] as String?;
    if (referenceId == null) {
      throw ApiException("Could not get OTP reference ID from the server.", statusCode: 200);
    }
    return referenceId;
  }

  /// Verifies an SMS OTP using the provided code and reference ID.
  Future<void> verifySmsOtp({required String otp, required String referenceId}) async {
    await _apiService.smsVerifyOtp(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      otp: otp,
      referenceId: referenceId,
    );
  }

  Future<void> submitCustomDocument({required File documentFile}) async {
    await _apiService.customDocumentVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      documentFile: documentFile,
    );
  }

  Future<void> submitPhNbiClearance({required String clearanceNo}) async {
    await _apiService.phNbiClearance(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      clearanceNo: clearanceNo,
    );
  }

  Future<void> submitPhNationalPolice({required String surname, required String clearanceNo}) async {
    await _apiService.phNationalPolice(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      surname: surname,
      clearanceNo: clearanceNo,
    );
  }

  Future<void> submitVoiceLiveness({required File audioFile}) async {
    await _apiService.voiceLivenessVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      audioFile: audioFile,
    );
  }

  Future<void> submitBusinessAml({required String businessName}) async {
    await _apiService.businessAmlVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      businessName: businessName,
    );
  }

  Future<void> submitFinlinkData({required Map<String, dynamic> formData}) async {
    await _apiService.finlinkVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      formData: formData,
    );
  }

  Future<void> submitKtpExtraction({required File imageFile}) async {
    final response = await _apiService.ktpDetailsExtraction(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      imageFile: imageFile,
    );
    // After extraction, we update the collectedData, similar to documentVerification.
    _updateStateFromDocumentResponse(response);
  }

  Future<void> submitKybComprehensive({
    required String companyName,
    required String countryCode,
    required String registrationNumber,
  }) async {
    await _apiService.kybComprehensiveVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      companyName: companyName,
      countryCode: countryCode,
      registrationNumber: registrationNumber,
    );
  }

  Future<void> submitEmailInsight({required String email}) async {
    await _apiService.emailSocialInsight(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      email: email,
    );
  }

  Future<void> submitPhoneInsight({required String phoneNumber, required String countryCode}) async {
    await _apiService.phoneSocialInsight(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      phoneNumber: phoneNumber,
      countryCode: countryCode,
    );
  }

  Future<void> submitCustomForm({required Map<String, dynamic> formData}) async {
    await _apiService.submitCustomForm(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      formData: formData,
    );
  }

  Future<void> submitPhilSysData({
    required String faceLivenessSessionId,
    String? qrData,
    String? pcn,
    Map<String, dynamic>? pcnFormData,
  }) async {
    await _apiService.philsysVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      faceLivenessSessionId: faceLivenessSessionId,
      qrData: qrData,
      pcn: pcn,
      pcnFormData: pcnFormData,
    );
  }

  Future<void> submitAuImmigrationData({
    required String familyName,
    required String givenName,
    required String dob,
    required String immigrationCardNumber,
  }) async {
    await _apiService.australiaImmigration(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      familyName: familyName,
      givenName: givenName,
      dob: dob,
      immigrationCardNumber: immigrationCardNumber,
    );
  }

  Future<void> submitAuCitizenCertData({
    required String familyName,
    String? givenName,
    required String dob,
    required String acquisitionDate,
    required String stockNumber,
  }) async {
    await _apiService.australiaCitizenCert(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      familyName: familyName,
      givenName: givenName,
      dob: dob,
      acquisitionDate: acquisitionDate,
      stockNumber: stockNumber,
    );
  }

  Future<void> submitAuBirthCertData({
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
    await _apiService.australiaBirthCert(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      familyName: familyName,
      givenName: givenName,
      dob: dob,
      registrationNumber: registrationNumber,
      registrationState: registrationState,
      registrationDate: registrationDate,
      certificateNumber: certificateNumber,
      datePrinted: datePrinted,
      registrationYear: registrationYear,
    );
  }

  Future<void> submitAuDeathCertData({
    required String familyName,
    required String givenName,
    required String doe,
    required String registrationNumber,
    required String registrationState,
    required String registrationDate,
    required String certificateNumber,
  }) async {
    await _apiService.australiaDeathCert(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      familyName: familyName,
      givenName: givenName,
      doe: doe,
      registrationNumber: registrationNumber,
      registrationState: registrationState,
      registrationDate: registrationDate,
      certificateNumber: certificateNumber,
    );
  }

  Future<void> submitAuAecData({
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
    await _apiService.australiaAec(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      familyName: familyName,
      givenName: givenName,
      dob: dob,
      suburb: suburb,
      postcode: postcode,
      state: state,
      streetName: streetName,
      streetType: streetType,
      streetNumber: streetNumber,
      unitNumber: unitNumber,
      habitationName: habitationName,
    );
  }

  Future<void> submitAuAsicMsicData({
    required String fullName,
    required String dob,
    required String cardNumber,
    required String cardExpiry,
    required String cardType,
  }) async {
    await _apiService.australiaAsicMsic(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      fullName: fullName,
      dob: dob,
      cardNumber: cardNumber,
      cardExpiry: cardExpiry,
      cardType: cardType,
    );
  }

  Future<void> submitAuDlData({
    required String familyName,
    String? middleName,
    required String givenName,
    required String dob,
    String? cardNumber,
    required String licenceNumber,
    required String stateOfIssue,
  }) async {
    await _apiService.australiaDrivingLicense(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      familyName: familyName,
      middleName: middleName,
      givenName: givenName,
      dob: dob,
      cardNumber: cardNumber,
      licenceNumber: licenceNumber,
      stateOfIssue: stateOfIssue,
    );
  }

  Future<void> submitAuVisaData({
    required String familyName,
    required String givenName,
    required String dob,
    required String passportNumber,
    required String countryOfIssue,
  }) async {
    await _apiService.australiaVisa(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      familyName: familyName,
      givenName: givenName,
      dob: dob,
      passportNumber: passportNumber,
      countryOfIssue: countryOfIssue,
    );
  }

  Future<void> submitAuMedicareData({
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
    await _apiService.australiaMedicare(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      name1: name1,
      name2: name2,
      name3: name3,
      name4: name4,
      cardExpiry: cardExpiry,
      cardNumber: cardNumber,
      cardType: cardType,
      individualReferenceNumber: individualReferenceNumber,
      dob: dob,
    );
  }

  Future<void> submitAuCentrelinkData({
    required String name,
    required String dob,
    required String cardExpiry,
    required String cardType,
    required String customerReferenceNumber,
  }) async {
    await _apiService.australiaCentrelink(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      name: name,
      dob: dob,
      cardExpiry: cardExpiry,
      cardType: cardType,
      customerReferenceNumber: customerReferenceNumber,
    );
  }

  Future<void> submitAuConcData({
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
    await _apiService.australiaChangeOfNameCert(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      familyName: familyName,
      givenName: givenName,
      newFamilyName: newFamilyName,
      newGivenName: newGivenName,
      dob: dob,
      registrationNumber: registrationNumber,
      registrationState: registrationState,
      registrationDate: registrationDate,
      certificateNumber: certificateNumber,
      datePrinted: datePrinted,
      registrationYear: registrationYear,
    );
  }

  Future<void> submitAuMarriageCertData({
    required String brideFamilyName,
    required String brideGivenName,
    required String groomFamilyName,
    required String groomGivenName,
    required String dob,
    required String registrationNumber,
    required String registrationState,
    String? registrationDate,
    String? certificateNumber,
    String? datePrinted,
    String? registrationYear,
  }) async {
    await _apiService.australiaMarriageCert(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
      brideFamilyName: brideFamilyName,
      brideGivenName: brideGivenName,
      groomFamilyName: groomFamilyName,
      groomGivenName: groomGivenName,
      dob: dob,
      registrationNumber: registrationNumber,
      registrationState: registrationState,
      registrationDate: registrationDate,
      certificateNumber: certificateNumber,
      datePrinted: datePrinted,
      registrationYear: registrationYear,
    );
  }

  /// Calls the endpoint to finalize the verification session on the backend.
  /// This should be called after all steps are successfully completed.
  Future<void> finalizeVerification() async {
    if (_flowState.userToken == null || _flowState.templateId == null || _flowState.verificationId == null) {
      throw Exception('Cannot finalize verification: Missing required IDs.');
    }

    await _apiService.finalizeVerification(
      userToken: _flowState.userToken!,
      templateId: _flowState.templateId!,
      verificationId: _flowState.verificationId!,
    );
    debugPrint("✅ Verification finalized successfully via repository.");
  }

  // --- State Navigation Methods ---

  /// Advances the flow to the next step.
  /// It adds the current step's index to the history stack to enable back navigation.
  void nextStep() {
    if (!_flowState.isLastStep) {
      final newHistory = List<int>.from(_flowState.history)..add(_flowState.currentStepIndex);

      _flowState = _flowState.copyWith(currentStepIndex: _flowState.currentStepIndex + 1, history: newHistory);
    } else {
      debugPrint("End of flow reached.");
    }
  }

  /// Navigates back to the previous step using the history stack.
  /// It pops the last index from the history and sets it as the current step index.
  void previousStep() {
    if (_flowState.history.isNotEmpty) {
      final lastIndex = _flowState.history.removeLast();
      _flowState = _flowState.copyWith(currentStepIndex: lastIndex, history: _flowState.history);
    }
  }
}
