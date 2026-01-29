import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math; // Added for rotation
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../verification/verification.dart';

class BioFaceCompareScreen extends StatefulWidget {
  const BioFaceCompareScreen({super.key});

  @override
  State<BioFaceCompareScreen> createState() => _BioFaceCompareScreenState();
}

class _BioFaceCompareScreenState extends State<BioFaceCompareScreen> {
  XFile? _image1;
  XFile? _image2;
  Uint8List? _image2Bytes;

  // Rotation State
  double _image1Rotation = 0;
  double _image2Rotation = 0;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      // 1. Register the submit function
      get.setContinueAction(_submit);

      final collectedData = get.flowState.collectedData;

      // 2. RESTORE LOGIC
      // Priority 1: Locally saved paths (user went back)
      if (collectedData['local_face_compare_image1'] != null) {
        final f = File(collectedData['local_face_compare_image1']);
        if (f.existsSync()) _image1 = XFile(f.path);
      }

      if (collectedData['local_face_compare_image2'] != null) {
        final f = File(collectedData['local_face_compare_image2']);
        if (f.existsSync()) {
          _image2 = XFile(f.path);
          _image2Bytes = null;
        }
      }

      // Priority 2: Data from previous steps (if not locally saved)
      if (_image1 == null) {
        final selfiePath = collectedData['liveSelfiePath'] as String?;
        if (selfiePath != null) _image1 = XFile(selfiePath);
      }

      if (_image2 == null && _image2Bytes == null) {
        final documentFaceBase64 = collectedData['faceImageBase64'] as String?;
        if (documentFaceBase64 != null) {
          _image2Bytes = base64Decode(documentFaceBase64);
        }
      }

      // Refresh UI if restored
      setState(() {});
    });
  }

  Future<void> getImage(int imageNumber) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (imageNumber == 1) {
          _image1 = XFile(pickedFile.path);
          _image1Rotation = 0; // Reset rotation on new image
        } else {
          _image2 = XFile(pickedFile.path);
          _image2Bytes = null; // Clear extracted bytes if manual upload
          _image2Rotation = 0; // Reset rotation
        }
      });
    }
  }

  void _rotateImage(int imageNumber) {
    setState(() {
      if (imageNumber == 1) {
        _image1Rotation += 90;
      } else {
        _image2Rotation += 90;
      }
    });
  }

  void _removeImage(int imageNumber) {
    setState(() {
      if (imageNumber == 1) {
        _image1 = null;
        _image1Rotation = 0;
      } else {
        _image2 = null;
        _image2Bytes = null;
        _image2Rotation = 0;
      }
    });
  }

  void _showImagePreview(dynamic image, double rotation) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: rotation * (math.pi / 180),
              child: image is XFile ? Image.file(File(image.path), fit: BoxFit.contain) : Image.memory(image as Uint8List, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_image1 == null || (_image2 == null && _image2Bytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide both images first.'), backgroundColor: Colors.red));
      return;
    }

    final get = context.read<Verification>();

    // 3. SAVE DATA LOCALLY
    get.updateStepData({
      'local_face_compare_image1': _image1?.path,
      'local_face_compare_image2': _image2?.path,
    });

    final success = await get.submitFaceCompare(context, liveSelfie: _image1!, manualImage2: _image2);

    if (!mounted) return;
    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Face comparison failed.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Verification>().designSettings?.settings;
    final textColor = settings?.textColor ?? Colors.black;
    final secondaryColor = settings?.secondaryColor ?? Colors.blue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // --- Header ---
                  const Text("Face Comparison", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Upload two images to perform biometric face comparison",
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 24),

                  // --- Images Row ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image 1
                      Expanded(
                          child: _buildUploadColumn(
                        title: "Reference Image *",
                        image: _image1,
                        imageBytes: null,
                        rotation: _image1Rotation,
                        onSelect: () => getImage(1),
                        onRotate: () => _rotateImage(1),
                        onRemove: () => _removeImage(1),
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                      )),

                      const SizedBox(width: 12),

                      // Image 2
                      Expanded(
                          child: _buildUploadColumn(
                        title: "Comparison Image *",
                        image: _image2,
                        imageBytes: _image2Bytes,
                        rotation: _image2Rotation,
                        onSelect: () => getImage(2),
                        onRotate: () => _rotateImage(2),
                        onRemove: () => _removeImage(2),
                        textColor: textColor,
                        secondaryColor: secondaryColor,
                      )),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text("Images should clearly show the face with good lighting and no obstructions",
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildUploadColumn({
    required String title,
    XFile? image,
    Uint8List? imageBytes,
    required double rotation,
    required VoidCallback onSelect,
    required VoidCallback onRotate,
    required VoidCallback onRemove,
    required Color textColor,
    required Color secondaryColor,
  }) {
    final hasImage = image != null || imageBytes != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        RichText(
            text: TextSpan(
                text: title.replaceAll('*', ''),
                style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                children: [if (title.contains('*')) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))])),
        const SizedBox(height: 8),

        // Dashed Box / Preview
        GestureDetector(
          onTap: hasImage ? () => _showImagePreview(image ?? imageBytes, rotation) : onSelect,
          child: hasImage
              ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: Transform.rotate(
                          angle: rotation * (math.pi / 180),
                          child: image != null ? Image.file(File(image.path), fit: BoxFit.cover) : Image.memory(imageBytes!, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    // Remove Button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                    // Rotate Button
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: InkWell(
                        onTap: onRotate,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                          child: const Icon(Icons.rotate_right, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                )
              : CustomPaint(
                  painter: _DashedBorderPainter(color: Colors.grey.shade300),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey.shade400),
                        const SizedBox(height: 4),
                        Text("Upload image", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text("JPG, JPEG or PNG", textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 12),

        // Select Button
        SizedBox(
          width: double.infinity,
          height: 36,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A), // Dark Blue from image
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: onSelect,
            icon: const Icon(Icons.upload_file, size: 16),
            label: const Text("Select Image", style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final Path path = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));
    final Path dashedPath = _dashPath(path, width: 5, space: 4);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final Path dest = Path();
    for (final ui.PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dest.addPath(metric.extractPath(distance, distance + width), Offset.zero);
        distance += width + space;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
