import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../verification/verification.dart';

class PhDrivingLicenseScreen extends StatefulWidget {
  const PhDrivingLicenseScreen({super.key});

  @override
  State<PhDrivingLicenseScreen> createState() => _PhDrivingLicenseScreenState();
}

class _PhDrivingLicenseScreenState extends State<PhDrivingLicenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _expiryController = TextEditingController();
  final _serialController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      // 1. Register the submit function to the Sticky Footer
      get.setContinueAction(_submitForm);

      // 2. Prefill Data
      final prefilledData = get.flowState.collectedData;
      _licenseController.text = prefilledData['docNumber'] ?? '';
      _expiryController.text = prefilledData['doe'] ?? '';
    });
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _expiryController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    DateTime initial;
    try {
      initial = _expiryController.text.isNotEmpty ? DateFormat('yyyy-MM-dd').parse(_expiryController.text) : now;
    } catch (_) {
      initial = now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365 * 10)),
      lastDate: now.add(const Duration(days: 365 * 20)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expiryController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final get = context.read<Verification>();
    final success = await get.submitPhDrivingLicenseData(
      context,
      licenseNumber: _licenseController.text,
      expiryDate: _expiryController.text,
      serialNumber: _serialController.text,
    );

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Verification failed.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Verification>().designSettings?.settings;
    final secondaryColor = settings?.secondaryColor ?? Colors.blue;
    final textColor = settings?.textColor ?? Colors.black;

    // Common Input Decoration
    InputDecoration inputDecoration(String hint) {
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: secondaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 1.0)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // --- Card Container ---
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
              ],
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_outlined, size: 22, color: textColor),
                            const SizedBox(width: 8),
                            Text(
                              "Philippines Driving License",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Enter your license details",
                          style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),

                  // --- Form Fields ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // License Number
                        _buildLabel("License Number *", textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _licenseController,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration("Enter license number"),
                          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter the license number.' : null,
                        ),
                        const SizedBox(height: 20),

                        // Serial Number
                        _buildLabel("Serial Number", textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _serialController,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration("Enter serial number (Optional)"),
                        ),
                        const SizedBox(height: 20),

                        // Expiration Date
                        _buildLabel("Expiration Date *", textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _expiryController,
                          readOnly: true,
                          onTap: _selectDate,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration("YYYY-MM-DD").copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please select the expiration date.' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Padding for Sticky Footer
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return RichText(
      text: TextSpan(
        text: text.replaceAll('*', ''),
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
        children: [
          if (text.contains('*'))
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}
