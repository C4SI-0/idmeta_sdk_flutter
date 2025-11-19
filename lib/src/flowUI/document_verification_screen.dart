import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:blinkid_flutter/microblink_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../verification/verification.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key});

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  bool _isInitializing = true;
  double _frontRotation = 0;
  double _backRotation = 0;

  File? _displayFrontImage;
  File? _apiFrontImage;
  File? _displayBackImage;
  File? _apiBackImage;

  final _scannerService = DocumentScannerService();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isManual = context.read<Verification>().flowState.isDocumentVerificationManualScan;
      if (isManual) {
        setState(() => _isInitializing = false);
      } else {
        _startScan();
      }
    });
  }

  Future<void> _startScan() async {
    setState(() => _isInitializing = true);
    final get = context.read<Verification>();
    final isMultiSide = get.flowState.isDocumentVerificationMultiSide;

    final ScanResult? result = isMultiSide ? await _scannerService.scanMultiSideDocument() : await _scannerService.scanSingleSideDocument();

    if (mounted && result != null) {
      setState(() {
        _displayFrontImage = result.displayImageFront;
        _apiFrontImage = result.apiImageFront;
        _displayBackImage = result.displayImageBack;
        _apiBackImage = result.apiImageBack;
        _isInitializing = false;
      });
      await _submitScanned(result.apiImageFront, result.apiImageBack);
    } else if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _pickImage(int imageNumber) async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      final imageFile = File(pickedFile.path);
      setState(() {
        if (imageNumber == 1) {
          _displayFrontImage = imageFile;
          _apiFrontImage = imageFile;
          _frontRotation = 0;
        } else {
          _displayBackImage = imageFile;
          _apiBackImage = imageFile;
          _backRotation = 0;
        }
      });
    }
  }

  void _rotateImage(int imageNumber) {
    setState(() {
      if (imageNumber == 1) {
        _frontRotation += 90;
      } else {
        _backRotation += 90;
      }
    });
  }

  Future<void> _submitManual() async {
    if (_apiFrontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload the front side image first.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final get = context.read<Verification>();
    final success = await get.submitDocument(context, front: _apiFrontImage!, back: _apiBackImage);
    if (!mounted) return;
    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Submission failed.')));
    }
  }

  Future<void> _submitScanned(File front, File? back) async {
    final get = context.read<Verification>();

    final success = await get.submitDocument(context, front: front, back: back);
    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Scan submission failed. Please try again.'),
        backgroundColor: Colors.red,
      ));
      setState(() {
        _displayFrontImage = null;
        _apiFrontImage = null;
        _displayBackImage = null;
        _apiBackImage = null;
      });
    }
  }

  void _showImagePreview(File image, double rotationAngle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Transform.rotate(
                  angle: rotationAngle * (math.pi / 180),
                  child: Image.file(image),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final get = context.watch<Verification>();
    final isLoading = get.isLoading;
    final isManualScan = get.flowState.isDocumentVerificationManualScan;
    final isMultiSide = get.flowState.isDocumentVerificationMultiSide;

    final buttonStyle = TextButton.styleFrom(
      backgroundColor: get.designSettings?.settings?.secondaryColor,
      foregroundColor: get.designSettings?.settings?.buttonTextColor,
      minimumSize: const Size.fromHeight(50),
    );

    if (_isInitializing) {
      return const Scaffold(
          body: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [CircularProgressIndicator(), SizedBox(height: 16), Text("Preparing scanner...")],
      )));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        children: <Widget>[
          TextButton.icon(
            icon: const Icon(Icons.document_scanner),
            style: TextButton.styleFrom(
              minimumSize: const Size(100, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: isLoading ? null : _startScan,
            label: const Text('Scan Document'),
          ),
          const SizedBox(height: 20),
          buildImageSection(
            title: isManualScan ? 'Front Side Image*' : 'Front Side Image',
            imageNumber: 1,
            image: _displayFrontImage,
            rotationAngle: _frontRotation,
            isManual: isManualScan,
          ),
          const SizedBox(height: 30),
          if (isMultiSide)
            buildImageSection(
              title: isManualScan ? 'Back Side Image' : 'Back Side Image (Optional)',
              imageNumber: 2,
              image: _displayBackImage,
              rotationAngle: _backRotation,
              isManual: isManualScan,
            ),
          if (isManualScan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20),
              child: TextButton(
                style: buttonStyle,
                onPressed: isLoading ? null : _submitManual,
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildImageSection({required String title, required int imageNumber, required File? image, required double rotationAngle, required bool isManual}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white70,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            if (isManual)
              GestureDetector(
                onTap: () => _pickImage(imageNumber),
                child: Container(
                  height: 35,
                  width: MediaQuery.of(context).size.width / 1.5,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                  child: const Center(child: Text('Choose File', style: TextStyle(fontWeight: FontWeight.bold))),
                ),
              ),
            if (image != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showImagePreview(image, rotationAngle),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 150),
                      child: Transform.rotate(
                        angle: rotationAngle * (math.pi / 180),
                        child: Image.file(image, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.rotate_right, size: 30),
                    onPressed: () => _rotateImage(imageNumber),
                  ),
                ],
              )
            else if (!isManual)
              Container(
                height: 75,
                width: 100,
                margin: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400)),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_outlined, color: Colors.grey[600], size: 20),
                      const SizedBox(height: 4),
                      Text('No Image', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ScanResult {
  final File displayImageFront;
  final File apiImageFront;
  final File? displayImageBack;
  final File? apiImageBack;

  ScanResult({
    required this.displayImageFront,
    required this.apiImageFront,
    this.displayImageBack,
    this.apiImageBack,
  });
}

class DocumentScannerService {
  //***************************Test Licenses only for Testing******************** */
  static const Map<String, String> _licenses = {
    'com.psslai.ko':
        'sRwCAA1jb20ucHNzbGFpLmtvAWxleUpEY21WaGRHVmtUMjRpT2pFM05UTTBOREV3T1RBNE1ERXNJa055WldGMFpXUkdiM0lpT2lKbVlqVTNNakZtT0MxaFlUTXlMVEpsTXpZdE1XTTFZaTB6TUROa016Wm1ZekV3T1dFaWZRPT1zCbYZmIAvF4MF2FxDdaAOM5njNhd2k2EIC6rBiBCMeAvmDA6skqViQ0u7ageG3EGE/8Mimu+tMM4ZsySTjRPf/c6x2RAsIhRLDa6HNCBaSeyHI4eGAXxZJSjki1+w',
    'com.traxionpay.app':
        'sRwCABJjb20udHJheGlvbnBheS5hcHABbGV5SkRjbVZoZEdWa1QyNGlPakUzTlRNME5ERXhNelV3TlRFc0lrTnlaV0YwWldSR2IzSWlPaUptWWpVM01qRm1PQzFoWVRNeUxUSmxNell0TVdNMVlpMHpNRE5rTXpabVl6RXdPV0VpZlE9PaB5Y1Ou5VdPjkSc2jxwmMffwzNFq1RdMHFNmcxlEUm5RuE6KUEpUTdlWo6Fe1U0gKZwyc8GHJT0DFvQ3cF+IV9DiGDID4wBa+R4lGdjI2l6IeWHG4QH6DylnxD6Kik=',
    'com.traxiontech.bibo':
        'sRwCABRjb20udHJheGlvbnRlY2guYmlibwFsZXlKRGNtVmhkR1ZrVDI0aU9qRTNOVE0wTkRFeU1UY3lORGdzSWtOeVpXRjBaV1JHYjNJaU9pSm1ZalUzTWpGbU9DMWhZVE15TFRKbE16WXRNV00xWWkwek1ETmtNelptWXpFd09XRWlmUT09XpNbFjrg+VSFAen7nClGxzKkeadW64bdmy6hV0FMpfrc5W33TVwQ5iGf2t409RREgFT5dGlUaZlHedH0aj7wQaNvWXN62pmsfN/zh5pOGDZeavpxfYYMaL2pzqpkgg==',
    'android.com.psslai.ko':
        'sRwCAA1jb20ucHNzbGFpLmtvAGxleUpEY21WaGRHVmtUMjRpT2pFM05UTTBOREV6TVRjeE1ERXNJa055WldGMFpXUkdiM0lpT2lKbVlqVTNNakZtT0MxaFlUTXlMVEpsTXpZdE1XTTFZaTB6TUROa016Wm1ZekV3T1dFaWZRPT0Kh1QG0Td+3pHFoowe0+1ZgiQb5gN2VFTSFf7IyGyO5OgW4YL8AGW7vsm38wnSwaC5BF8/tN9xnJ7jSI7VBfV/j1aIGdq1y5V+yy4Avj1Bp0+rKDOzZQ1VxRntYZm7',
    'android.com.traxionpay.app':
        'sRwCABJjb20udHJheGlvbnBheS5hcHAAbGV5SkRjbVZoZEdWa1QyNGlPakUzTlRNME5ERXpOREF4T0RFc0lrTnlaV0YwWldSR2IzSWlPaUptWWpVM01qRm1PQzFoWVRNeUxUSmxNell0TVdNMVlpMHpNRE5rTXpabVl6RXdPV0VpZlE9PYVyKUVZ40moRXa/ZA/u2fIirfo7NPGEpxai27HyK9G7449M/7NcviC2Hvw9wGkE8D2mhkEkw5iyD09qQkH//QhCWOWH5NlLeH9CsJp73/2f7yytF1GxiG8zyCsJ/p4=',
    'android.com.traxiontech.bibo':
        'sRwCABRjb20udHJheGlvbnRlY2guYmlibwBsZXlKRGNtVmhkR1ZrVDI0aU9qRTNOVE0wTkRFek5qVTRPRGdzSWtOeVpXRjBaV1JHYjNJaU9pSm1ZalUzTWpGbU9DMWhZVE15TFRKbE16WXRNV00xWWkwek1ETmtNelptWXpFd09XRWlmUT09BgRdLZ5+uhvjgUjEnifH/nzT2sqybFYvDuPXZVjQ3EyhK0AzJbM7+XrZ+KjSOZ5j1Q5Ela4DRDx/knLz7nB9xt9HFydbQO0PsCRpiRS7Z3+kHcUC0nyfpIIqJPbDew==',
  };
  static const String _defaultLicense =
      "sRwCABZjb20uaWQuaWRtZXRhX3Nkay5ob3N0AGxleUpEY21WaGRHVmtUMjRpT2pFM05EazNNelV5TnpVeE56Y3NJa055WldGMFpXUkdiM0lpT2lKbVlqVTNNakZtT0MxaFlUTXlMVEpsTXpZdE1XTTFZaTB6TUROa016Wm1ZekV3T1dFaWZRPT1ORyI35Qwc40ZjOtb4AU3o2ZeuIE2GIC2P9YN+k+e3HnvD0wL0wZ+fUAFmss8AqTZgZEVzWRGDeteQfTbnDtBGSgnaCfHVFIvYlOdhaBXF9GcWew2y6uhISvX0ctCOP7jIoz6YD30ZUkwScQ==";
  //***************************Test Licenses******************** */

  Future<String> _getLicenseKey() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final key = Platform.isAndroid ? 'android.${packageInfo.packageName}' : packageInfo.packageName;
    return _licenses[key] ?? _defaultLicense;
  }

  Future<File> _base64ToFile(String base64Str, String fileName) async {
    final bytes = base64Decode(base64Str);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<ScanResult?> scanMultiSideDocument() async {
    try {
      var idRecognizer = BlinkIdMultiSideRecognizer()
        ..returnFullDocumentImage = true
        ..saveCameraFrames = true;
      BlinkIdOverlaySettings settings = BlinkIdOverlaySettings();
      var results = await MicroblinkScanner.scanWithCamera(RecognizerCollection([idRecognizer]), settings, await _getLicenseKey());
      if (results.isEmpty) return null;
      for (var result in results) {
        if (result is BlinkIdMultiSideRecognizerResult) {
          if (result.fullDocumentFrontImage == null || result.frontCameraFrame == null) return null;
          final displayFront = await _base64ToFile(result.fullDocumentFrontImage!, "display_front.jpg");
          final apiFront = await _base64ToFile(result.frontCameraFrame!, "api_front.jpg");
          File? displayBack;
          File? apiBack;
          if (result.fullDocumentBackImage != null &&
              result.fullDocumentBackImage!.isNotEmpty &&
              result.backCameraFrame != null &&
              result.backCameraFrame!.isNotEmpty) {
            displayBack = await _base64ToFile(result.fullDocumentBackImage!, "display_back.jpg");
            apiBack = await _base64ToFile(result.backCameraFrame!, "api_back.jpg");
          }
          return ScanResult(displayImageFront: displayFront, apiImageFront: apiFront, displayImageBack: displayBack, apiImageBack: apiBack);
        }
      }
      return null;
    } on PlatformException {
      return null;
    }
  }

  Future<ScanResult?> scanSingleSideDocument() async {
    try {
      var idRecognizer = BlinkIdSingleSideRecognizer()
        ..returnFullDocumentImage = true
        ..saveCameraFrames = true;
      BlinkIdOverlaySettings settings = BlinkIdOverlaySettings();
      var results = await MicroblinkScanner.scanWithCamera(RecognizerCollection([idRecognizer]), settings, await _getLicenseKey());
      if (results.isEmpty) return null;
      for (var result in results) {
        if (result is BlinkIdSingleSideRecognizerResult) {
          if (result.fullDocumentImage == null || result.cameraFrame == null) return null;
          final displayFront = await _base64ToFile(result.fullDocumentImage!, "display_front.jpg");
          final apiFront = await _base64ToFile(result.cameraFrame!, "api_front.jpg");
          return ScanResult(displayImageFront: displayFront, apiImageFront: apiFront);
        }
      }
      return null;
    } on PlatformException {
      return null;
    }
  }
}
