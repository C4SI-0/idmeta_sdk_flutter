#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint idmeta_sdk_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  #
  # 1. --- Core Package Information ---
  # These values are now synchronized with your pubspec.yaml file.
  #
  s.name             = 'idmeta_sdk_flutter'
  s.version          = '1.0.0' # Updated to match pubspec.yaml
  s.summary          = 'IDMeta Flutter SDK for identity verification.' # Updated from pubspec.yaml
  s.description      = <<-DESC
IDMeta Flutter SDK for identity verification. This is a beta version for initial testing and integration.
                       DESC
  s.homepage         = 'https://github.com/C4SI-0/idmeta_sdk_flutter.git' # Updated from pubspec.yaml
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'C4SI-0' => '' } # Updated from repository URL
  s.source           = { :path => '.' }

  #
  # 2. --- File and Platform Configuration ---
  #
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0' # This is a reasonable minimum, but check your native dependencies.

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  #
  # 3. --- Critical: Privacy Manifest ---
  # Because your package uses the camera and microphone, you MUST include a privacy manifest.
  # Create the file 'ios/Resources/PrivacyInfo.xcprivacy' and then uncomment the line below.
  #
  s.resource_bundles = {'idmeta_sdk_flutter_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end