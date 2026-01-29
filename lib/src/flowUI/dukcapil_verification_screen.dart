import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../verification/verification.dart';

class DukcapilVerificationScreen extends StatefulWidget {
  const DukcapilVerificationScreen({super.key});

  @override
  State<DukcapilVerificationScreen> createState() => _DukcapilVerificationScreenState();
}

class _DukcapilVerificationScreenState extends State<DukcapilVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nikController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      // 1. Register the submit function to the Sticky Footer
      get.setContinueAction(_submitForm);

      // 2. Restore / Prefill Data
      final data = get.flowState.collectedData;

      // Logic: Saved Manual Input -> Extracted Data -> Empty
      _nameController.text = data['dukcapil_name'] ?? data['fullName'] ?? data['firstName'] ?? '';
      _nikController.text = data['dukcapil_nik'] ?? data['docNumber'] ?? '';
      _dobController.text = data['dukcapil_dob'] ?? data['dob'] ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    DateTime initial;
    try {
      initial = _dobController.text.isNotEmpty ? DateFormat('yyyy-MM-dd').parse(_dobController.text) : now;
    } catch (_) {
      initial = now;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
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
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final get = context.read<Verification>();

    // 3. Save Data Locally
    get.updateStepData({
      'dukcapil_name': _nameController.text,
      'dukcapil_nik': _nikController.text,
      'dukcapil_dob': _dobController.text,
    });

    final success = await get.submitDukcapilData(
      context,
      name: _nameController.text,
      dob: _dobController.text,
      nik: _nikController.text,
    );

    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Dukcapil verification failed.'),
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
                            Icon(Icons.fact_check_outlined, size: 22, color: textColor),
                            const SizedBox(width: 8),
                            Text(
                              "Dukcapil Verification",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Verify your NIK details",
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
                        // Name
                        _buildLabel("Full Name *", textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration("Enter your full name"),
                          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter a name.' : null,
                        ),
                        const SizedBox(height: 20),

                        // NIK
                        _buildLabel("NIK Number *", textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nikController,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration("Enter 16-digit NIK"),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value?.trim().isEmpty ?? true) return 'Please enter a NIK number.';
                            if (value!.length != 16) return 'NIK must be 16 digits.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // DOB
                        _buildLabel("Date of Birth *", textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          onTap: _selectDate,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration("YYYY-MM-DD").copyWith(
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please select a date of birth.' : null,
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
