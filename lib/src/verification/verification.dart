import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/service.dart';
import '../modal/flow_sate.dart';
import '../modal/settings.dart';
import '../core/repository.dart';
import '../widgets/loader.dart';

/// A [ChangeNotifier] that acts as the central state management hub for the verification process.
///
/// This class orchestrates the entire verification flow. It communicates with the
/// [_repository] to manage the flow state and execute business logic, and with the
/// [_apiService] for auxiliary data fetching (like UI settings).
///
/// The UI widgets listen to this provider to get the current state (e.g., loading status,
/// error messages, current step) and to trigger actions (e.g., submitting data, navigating).
class Verification with ChangeNotifier {
  /// The repository responsible for managing the verification state and API interactions.
  final VerificationRepository _repository;

  /// The service for direct API calls, such as fetching design settings.
  final ApiService _apiService;

  /// Creates a [Verification] provider.
  ///
  /// Requires a [VerificationRepository] and an [ApiService] for its operation.
  Verification({required VerificationRepository repository, required ApiService apiService})
      : _repository = repository,
        _apiService = apiService;

  // --- State Properties ---

  /// A general loading indicator, `true` when any background task is running.
  bool _isLoading = true;

  /// Public getter for the loading state.
  bool get isLoading => _isLoading;

  /// A specific loading indicator, `true` only when the initial verification flow is being started.
  bool _isStartingFlow = false;

  /// Public getter for the flow-starting state.
  bool get isStartingFlow => _isStartingFlow;

  /// Holds the message of the last error that occurred.
  String? _errorMessage;

  /// Public getter for the error message.
  String? get errorMessage => _errorMessage;

  /// A flag that becomes `true` after the entire verification flow is successfully finalized.
  bool _isFlowCompleted = false;

  /// Public getter for the flow completion status.
  bool get isFlowCompleted => _isFlowCompleted;

  /// Holds the fetched UI design and theme settings.
  DesignSettings? _designSettings;

  /// Public getter for the design settings.
  DesignSettings? get designSettings => _designSettings;

  /// A direct accessor to the current state of the verification flow from the repository.
  VerificationFlowState get flowState => _repository.flowState;

  /// A private helper method to wrap asynchronous tasks with common state management logic.
  ///
  /// It sets loading states, clears previous errors, and handles exceptions in a
  /// consistent way for all repository calls. This reduces boilerplate code in the
  /// public methods.
  Future<T> _runTask<T>(Future<T> Function() task) async {
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    try {
      // Execute the provided async task.
      return await task();
    } on ApiException catch (e) {
      _errorMessage = e.message;
      rethrow; // Rethrow to be caught by the calling method.
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initializes the provider with the necessary user and template IDs.
  ///
  /// This should be the first method called after the provider is created.
  void initialize({required String userToken, required String templateId}) {
    _repository.initialize(userToken: userToken, templateId: templateId);
    _loadInitialData();
  }

  /// Fetches initial data required for the UI, such as design settings.
  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _designSettings = await _apiService.getDesignSettings(templateId: flowState.templateId!);
    } catch (e) {
      _errorMessage = "Failed to load initial settings.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts the verification flow by making the initial API call.
  ///
  /// Returns `true` on success and `false` on failure.
  Future<bool> startVerificationFlow() async {
    _isStartingFlow = true;
    notifyListeners();
    try {
      await _repository.startVerification();
      return true;
    } catch (e) {
      return false;
    } finally {
      _isStartingFlow = false;
      notifyListeners();
    }
  }

  // --- Data Submission Methods ---
  // Each of the following methods follows a similar pattern:
  // 1. Show a loading overlay on the screen.
  // 2. Wrap the repository call in the `_runTask` helper.
  // 3. Return `true` for success, `false` for failure.
  // 4. Hide the loader in a `finally` block to ensure it's always dismissed.

  /// Submits the front and optionally the back side of a document.
  Future<bool> submitDocument(BuildContext context, {required File front, File? back}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitDocument(front, back));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Submits a live selfie for face comparison.
  Future<bool> submitFaceCompare(BuildContext context, {required XFile liveSelfie, XFile? manualImage2}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitFaceCompare(liveSelfie: liveSelfie, manualImage2: manualImage2));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Submits a username and image for biometric registration.
  Future<bool> submitBiometricRegistration(BuildContext context, {required String username, required XFile image}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitBiometricRegistration(username: username, image: image));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Submits an image for biometric verification against a registered user.
  Future<bool> submitBiometricVerification(BuildContext context, {required XFile image}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitBiometricVerification(image: image));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Submits user data for an AML (Anti-Money Laundering) check.
  Future<bool> submitAmlData(BuildContext context, {required String name, String? dob, String? gender}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAmlData(name: name, dob: dob, gender: gender));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  // [NOTE: The following methods are documented implicitly by the pattern established above.]
  // [Each method submits specific data for a verification step.]

  Future<bool> submitDukcapilData(BuildContext context, {required String name, required String dob, required String nik}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitDukcapilData(name: name, dob: dob, nik: nik));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitDukcapilFaceMatchData(BuildContext context, {required String name, required String dob, required String nik, required File image}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitDukcapilFaceMatchData(name: name, dob: dob, nik: nik, image: image));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhDrivingLicenseData(BuildContext context,
      {required String licenseNumber, required String expiryDate, required String serialNumber}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhDrivingLicenseData(licenseNumber: licenseNumber, expiryDate: expiryDate, serialNumber: serialNumber));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhSocialSecurityData(BuildContext context, {required String sssNumber}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhSocialSecurityData(sssNumber: sssNumber));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuPassportData(BuildContext context,
      {required String lastName, required String givenName, required String dob, required String gender, required String passportNumber}) async {
    showLoader(context);
    try {
      await _runTask(
          () => _repository.submitAuPassportData(lastName: lastName, givenName: givenName, dob: dob, gender: gender, passportNumber: passportNumber));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhPrcData(BuildContext context, {required String profession, String? firstName, String? lastName, String? licenseNo, String? dob}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhPrcData(profession: profession, firstName: firstName, lastName: lastName, licenseNo: licenseNo, dob: dob));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Submits a payload obtained from a QR code.
  Future<bool> submitQrCode(BuildContext context, {required Map<String, dynamic> qrPayload}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitQrCode(qrPayload: qrPayload));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Sends an OTP to a phone number. Returns a reference ID on success.
  Future<String?> sendSmsOtp(BuildContext context, {required String phoneNumber, required String countryCode}) async {
    showLoader(context);
    try {
      return await _runTask(() => _repository.sendSmsOtp(phoneNumber: phoneNumber, countryCode: countryCode));
    } catch (_) {
      return null;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Verifies an SMS OTP using the provided code and reference ID.
  Future<bool> verifySmsOtp(BuildContext context, {required String otp, required String referenceId}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.verifySmsOtp(otp: otp, referenceId: referenceId));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Sends an OTP to an email address. Returns a reference ID on success.
  Future<String?> sendEmailOtp(BuildContext context, {required String email}) async {
    showLoader(context);
    try {
      return await _runTask(() => _repository.sendEmailOtp(email: email));
    } catch (_) {
      return null;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Verifies an email OTP using the provided code and reference ID.
  Future<bool> verifyEmailOtp(BuildContext context, {required String otp, required String referenceId}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.verifyEmailOtp(otp: otp, referenceId: referenceId));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitCustomDocument(BuildContext context, {required File documentFile}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitCustomDocument(documentFile: documentFile));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhNbiClearance(BuildContext context, {required String clearanceNo}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhNbiClearance(clearanceNo: clearanceNo));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhNationalPolice(BuildContext context, {required String surname, required String clearanceNo}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhNationalPolice(surname: surname, clearanceNo: clearanceNo));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Submits an audio file for voice liveness verification.
  Future<bool> submitVoiceLiveness(BuildContext context, {required File audioFile}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitVoiceLiveness(audioFile: audioFile));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitBusinessAml(BuildContext context, {required String businessName}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitBusinessAml(businessName: businessName));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitFinlinkData(BuildContext context, {required Map<String, dynamic> formData}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitFinlinkData(formData: formData));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitKtpExtraction(BuildContext context, {required File imageFile}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitKtpExtraction(imageFile: imageFile));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitKybComprehensive(
    BuildContext context, {
    required String companyName,
    required String countryCode,
    required String registrationNumber,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitKybComprehensive(
            companyName: companyName,
            countryCode: countryCode,
            registrationNumber: registrationNumber,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitEmailInsight(BuildContext context, {required String email}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitEmailInsight(email: email));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhoneInsight(BuildContext context, {required String phoneNumber, required String countryCode}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhoneInsight(phoneNumber: phoneNumber, countryCode: countryCode));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Submits data from a dynamically generated form.
  Future<bool> submitCustomForm(BuildContext context, {required Map<String, dynamic> formData}) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitCustomForm(formData: formData));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitPhilSysData(
    BuildContext context, {
    required String faceLivenessSessionId,
    String? qrData,
    String? pcn,
    Map<String, dynamic>? pcnFormData,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitPhilSysData(
            faceLivenessSessionId: faceLivenessSessionId,
            qrData: qrData,
            pcn: pcn,
            pcnFormData: pcnFormData,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuImmigrationData(
    BuildContext context, {
    required String familyName,
    required String givenName,
    required String dob,
    required String immigrationCardNumber,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuImmigrationData(
            familyName: familyName,
            givenName: givenName,
            dob: dob,
            immigrationCardNumber: immigrationCardNumber,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuCitizenCertData(
    BuildContext context, {
    required String familyName,
    String? givenName,
    required String dob,
    required String acquisitionDate,
    required String stockNumber,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuCitizenCertData(
            familyName: familyName,
            givenName: givenName,
            dob: dob,
            acquisitionDate: acquisitionDate,
            stockNumber: stockNumber,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuBirthCertData(
    BuildContext context, {
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
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuBirthCertData(
            familyName: familyName,
            givenName: givenName,
            dob: dob,
            registrationNumber: registrationNumber,
            registrationState: registrationState,
            registrationDate: registrationDate,
            certificateNumber: certificateNumber,
            datePrinted: datePrinted,
            registrationYear: registrationYear,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuDeathCertData(
    BuildContext context, {
    required String familyName,
    required String givenName,
    required String doe,
    required String registrationNumber,
    required String registrationState,
    required String registrationDate,
    required String certificateNumber,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuDeathCertData(
            familyName: familyName,
            givenName: givenName,
            doe: doe,
            registrationNumber: registrationNumber,
            registrationState: registrationState,
            registrationDate: registrationDate,
            certificateNumber: certificateNumber,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuAecData(
    BuildContext context, {
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
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuAecData(
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
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuAsicMsicData(
    BuildContext context, {
    required String fullName,
    required String dob,
    required String cardNumber,
    required String cardExpiry,
    required String cardType,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuAsicMsicData(
            fullName: fullName,
            dob: dob,
            cardNumber: cardNumber,
            cardExpiry: cardExpiry,
            cardType: cardType,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuDlData(
    BuildContext context, {
    required String familyName,
    String? middleName,
    required String givenName,
    required String dob,
    String? cardNumber,
    required String licenceNumber,
    required String stateOfIssue,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuDlData(
            familyName: familyName,
            middleName: middleName,
            givenName: givenName,
            dob: dob,
            cardNumber: cardNumber,
            licenceNumber: licenceNumber,
            stateOfIssue: stateOfIssue,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuVisaData(
    BuildContext context, {
    required String familyName,
    required String givenName,
    required String dob,
    required String passportNumber,
    required String countryOfIssue,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuVisaData(
            familyName: familyName,
            givenName: givenName,
            dob: dob,
            passportNumber: passportNumber,
            countryOfIssue: countryOfIssue,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuMedicareData(
    BuildContext context, {
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
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuMedicareData(
            name1: name1,
            name2: name2,
            name3: name3,
            name4: name4,
            cardExpiry: cardExpiry,
            cardNumber: cardNumber,
            cardType: cardType,
            individualReferenceNumber: individualReferenceNumber,
            dob: dob,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuCentrelinkData(
    BuildContext context, {
    required String name,
    required String dob,
    required String cardExpiry,
    required String cardType,
    required String customerReferenceNumber,
  }) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuCentrelinkData(
            name: name,
            dob: dob,
            cardExpiry: cardExpiry,
            cardType: cardType,
            customerReferenceNumber: customerReferenceNumber,
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuConcData(
    BuildContext context, {
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
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuConcData(
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
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  Future<bool> submitAuMarriageCertData(
    BuildContext context, {
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
    showLoader(context);
    try {
      await _runTask(() => _repository.submitAuMarriageCertData(
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
          ));
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  /// Finalizes the verification process on the backend.
  Future<bool> finalizeVerification(BuildContext context) async {
    showLoader(context);
    try {
      await _runTask(() => _repository.finalizeVerification());
      return true;
    } catch (_) {
      return false;
    } finally {
      if (context.mounted) hideLoader(context);
    }
  }

  // --- Navigation Methods ---

  /// Advances the user to the next screen in the verification flow.
  ///
  /// If the current step is the last one, it triggers the `finalizeVerification` process.
  /// Otherwise, it simply updates the state to show the next step.
  void nextScreen(BuildContext context) {
    if (flowState.isLastStep) {
      debugPrint("Last step completed. Finalizing verification...");
      finalizeVerification(context).then((success) {
        if (!context.mounted) return;
        if (success) {
          _isFlowCompleted = true;
          notifyListeners();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(errorMessage ?? 'Failed to finalize verification.'),
            backgroundColor: Colors.red,
          ));
        }
      });
    } else {
      _repository.nextStep();
      notifyListeners();
    }
  }

  /// Navigates the user to the previous screen in the verification flow.
  void previousScreen() {
    _repository.previousStep();
    notifyListeners();
  }
}
