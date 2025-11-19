import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/FlowUI/au_conc_screen.dart';
import 'package:idmeta_sdk_flutter/src/FlowUI/au_marriage_cert_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_aec_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_asic_msic_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_birth_cert_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_centrelink_card_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_citizen_cert_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_death_cert_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_dl_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_immigration_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_medicare_card_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/au_visa_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/business_aml_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/dynamic_custom_form_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/email_insight_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/finlink.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/ktp_extraction_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/kyb_comprehensive_screen.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/philsys/philsys_flow_container.dart';
import 'package:idmeta_sdk_flutter/src/flowUI/phone_insight_screen.dart';
import '../flowUI/au_passport_screen.dart';
import '../flowUI/biometric_face_compare.dart';
import '../flowUI/biometric_registeration.dart';
import '../flowUI/biometric_verification.dart';
import '../flowUI/custom_document_screen.dart';
import '../flowUI/dukcapil_face_match_screen.dart';
import '../flowUI/dukcapil_verification_screen.dart';
import '../flowUI/email_verification_screen.dart';
import '../flowUI/ph_driving_license_screen.dart';
import '../flowUI/ph_national_police_screen.dart';
import '../flowUI/ph_nbi_clearance_screen.dart';
import '../flowUI/ph_prc_screen.dart';
import '../flowUI/ph_social_security_screen.dart';
import '../flowUI/aml_verification_screen.dart';
import '../flowUI/document_verification_screen.dart';
import '../flowUI/qr_verification_screen.dart';
import '../flowUI/sms_verification_screen.dart';
import '../flowUI/voice_liveness_screen.dart';

/// A mapping from API-defined verification step keys to their corresponding UI screen widgets.
///
/// This map is used by the `FlowScreen` to dynamically determine which widget to display
/// for the current step of the verification process. The keys must match the `tool`
/// names returned by the backend's `start-verification-flow` endpoint.
final Map<String, Widget> apiScreenMapping = {
  'document_verification': const DocumentVerificationScreen(),
  'document_verification_v2': const DocumentVerificationScreen(),
  'biometrics_face_compare': const BioFaceCompareScreen(),
  'biometrics_registration': const BiometricRegistrationScreen(),
  'biometrics_verification': const BiometricVerificationScreen(),
  'aml': const AmlVerificationScreen(),
  'business_aml': const BusinessAmlScreen(),
  'dukcapil': const DukcapilVerificationScreen(),
  'dukcapil_facematch': const DukcapilFaceMatchScreen(),
  'philippines_driving_license': const PhDrivingLicenseScreen(),
  'philippines_social_security': const PhSocialSecurityScreen(),
  'australia_passport': const AuPassportScreen(),
  'qr_verification': const QrVerificationScreen(),
  'sms_verification': const SmsVerificationScreen(),
  'philippines_prc': const PhPrcScreen(),
  'email_verification': const EmailVerificationScreen(),
  'custom_document': const CustomDocumentScreen(),
  'philippines_nbi_clearance': const PhNbiClearanceScreen(),
  'philippines_national_police': const PhNationalPoliceScreen(),
  'biometrics_voice_liveness': const VoiceLivenessScreen(),
  'finlink': const FinLinkScreen(),
  'ktp_details_extraction': const KtpExtractionScreen(),
  'kyb_comprehensive': const KybComprehensiveScreen(),
  'phone_social': const PhoneInsightScreen(),
  'email_social': const EmailInsightScreen(),
  'custom_form': const DynamicCustomFormScreen(),
  'scan_qr': const PhilSysScreen(),
  'australia_immigration': const AuImmigrationScreen(),
  'australia_citizenship_certificate': const AuCitizenCertScreen(),
  'australia_death_certificate': const AuDeathCertScreen(),
  'australia_birth_certificate': const AuBirthCertScreen(),
  'australia_asic_misc': const AuAsicMsicScreen(),
  'australia_aec': const AuAecScreen(),
  'australia_driver_license': const AuDlScreen(),
  'australia_medicare_card': const AuMedicareCardScreen(),
  'australia_centrelink_card': const AuCentrelinkCardScreen(),
  'australia_change_of_name_certificate': const AuConcScreen(),
  'australia_marriage_certificate': const AuMarriageCertScreen(),
  'australia_visa': const AuVisaScreen(),
};

/// A mapping from API-defined verification step keys to human-readable display names.
///
/// This map is used to show a user-friendly title in the `AppBar` of the `FlowScreen`
/// for the current verification step. The keys should correspond to the keys in
/// [apiScreenMapping].
final Map<String, String> apiPlanDisplayNames = {
  'document_verification_v2': 'Document Verification v2',
  'document_verification': 'Document Verification',
  'biometrics_face_compare': 'Biometric Face Comparison',
  'biometrics_registration': 'Biometric Registration',
  'biometrics_verification': 'Biometric Verification',
  'aml': 'AML Verification',
  'business_aml': 'AML Business Verification',
  'sms_verification': 'SMS Verification',
  'custom_document': 'Custom Document',
  'dukcapil_facematch': 'Dukcapil Face Match',
  'dukcapil': 'Dukcapil Verification',
  'philippines_nbi_clearance': 'Philippines NBI Clearance',
  'philippines_national_police': 'Philippines National Police',
  'philippines_prc': 'Philippines PRC',
  'philippines_driving_license': 'Philippines Driving License',
  'australia_passport': 'Australia Passport',
  'biometrics_voice_liveness': 'Biometric Voice Liveness',
  'email_verification': 'Email Verification',
  'philippines_social_security': 'Philippines Social Security',
  'qr_verification': 'Qr Verification',
  'finlink': 'Finlink',
  'ktp_details_extraction': 'KTP Details Extraction',
  'kyb_comprehensive': 'KYB Comprehensive',
  'phone_social': 'Phone Social Insights',
  'email_social': 'Email Social Insights',
  'custom_form': 'Custom Form',
  'scan_qr': 'PhilSys Check',
  'australia_immigration': 'Australia Immigration',
  'australia_citizenship_certificate': 'Australia Citizenship Certificate',
  'australia_death_certificate': 'Australia Death Certificate',
  'australia_birth_certificate': 'Australia Birth Certificate',
  'australia_asic_misc': 'Australia Asic Msic',
  'australia_aec': 'Australia Aec',
  'australia_driver_license': 'Australia Driving License',
  'australia_medicare_card': 'Australia Medicare Card',
  'australia_centrelink_card': 'Australia Centre Link Card',
  'australia_change_of_name_certificate': 'Australia Change Of Name Certificate',
  'australia_marriage_certificate': 'Australia Marriage Certificate',
  'australia_visa': 'Australia Visa',
};
