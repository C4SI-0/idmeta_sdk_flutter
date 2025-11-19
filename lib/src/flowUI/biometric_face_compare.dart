import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
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
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();
      final collectedData = get.flowState.collectedData;

      final documentFaceBase64 = collectedData['faceImageBase64'] as String?;
      if (documentFaceBase64 != null) {
        setState(() => _image2Bytes = base64Decode(documentFaceBase64));
      }

      final selfiePath = collectedData['liveSelfiePath'] as String?;
      if (selfiePath != null) {
        setState(() => _image1 = XFile(selfiePath));
      }
    });
  }

  Future<void> getImage(int imageNumber, {bool fromCamera = false}) async {
    final pickedFile = await picker.pickImage(source: fromCamera ? ImageSource.camera : ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (imageNumber == 1) {
          _image1 = XFile(pickedFile.path);
        } else {
          _image2 = XFile(pickedFile.path);
          _image2Bytes = null;
        }
      });
    }
  }

  void _showImagePreview(dynamic image) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              image is XFile ? Image.file(File(image.path), fit: BoxFit.contain) : Image.memory(image as Uint8List, fit: BoxFit.contain),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_image1 == null || (_image2 == null && _image2Bytes == null)) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text('Please provide both images first.'),
            actions: <Widget>[
              TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop()),
            ],
          );
        },
      );
      return;
    }

    final get = context.read<Verification>();

    final success = await get.submitFaceCompare(
      context,
      liveSelfie: _image1!,
      manualImage2: _image2,
    );

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Face comparison failed.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final get = context.watch<Verification>();
    final isLoading = get.isLoading;
    final settings = get.designSettings?.settings;

    final buttonStyle = TextButton.styleFrom(
      backgroundColor: settings?.secondaryColor,
      foregroundColor: settings?.buttonTextColor,
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: <Widget>[
          _buildImageSection(
            title: 'Image 1*',
            image: _image1,
            onPick: (fromCamera) => getImage(1, fromCamera: fromCamera),
          ),
          const SizedBox(height: 30),
          _image2Bytes == null
              ? _buildImageSection(
                  title: 'Image 2*',
                  image: _image2,
                  onPick: (fromCamera) => getImage(2, fromCamera: fromCamera),
                )
              : _buildDocumentFaceSection(),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                style: buttonStyle,
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)))
                    : const Text('Next', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentFaceSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[200],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text('Image 2* (From Document)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            if (_image2Bytes != null)
              GestureDetector(
                onTap: () => _showImagePreview(_image2Bytes!),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Center(child: Image.memory(_image2Bytes!, fit: BoxFit.cover)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required XFile? image,
    required void Function(bool fromCamera) onPick,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white70,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => onPick(false),
                  child: Container(
                    height: 35,
                    width: MediaQuery.of(context).size.width / 2.5,
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                    child: const Center(child: Text('Choose File')),
                  ),
                ),
                GestureDetector(
                  onTap: () => onPick(true),
                  child: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary,
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),
                ),
              ],
            ),
            if (image != null)
              GestureDetector(
                onTap: () => _showImagePreview(image),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Center(child: Image.file(File(image.path), fit: BoxFit.cover)),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}
