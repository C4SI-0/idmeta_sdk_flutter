import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../verification/verification.dart';

const List<(String, String)> genderOptions = [
  ('Any', 'any'),
  ('Male', 'male'),
  ('Female', 'female'),
];

class AmlVerificationScreen extends StatefulWidget {
  const AmlVerificationScreen({super.key});

  @override
  State<AmlVerificationScreen> createState() => _AmlVerificationScreenState();
}

class _AmlVerificationScreenState extends State<AmlVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedGenderValue = 'any';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      // 1. Register the submit function with the parent FlowScreen
      get.setContinueAction(_submitForm);

      // 2. Prefill Data
      final prefilledData = get.flowState.collectedData;
      _nameController.text = prefilledData['fullName'] ?? prefilledData['firstName'] ?? '';
      _dobController.text = prefilledData['dob'] ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _dobController.text.isNotEmpty ? (DateTime.tryParse(_dobController.text) ?? now) : now;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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

    final success = await get.submitAmlData(
      context,
      name: _nameController.text,
      dob: _dobController.text.isNotEmpty ? _dobController.text : null,
      gender: _selectedGenderValue,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to next screen (this clears the current action)
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(get.errorMessage ?? 'Submission failed.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Verification>().designSettings?.settings;

    // Theme Colors
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: secondaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
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
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
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
                            Icon(Icons.shield_outlined, size: 20, color: textColor),
                            const SizedBox(width: 8),
                            Text(
                              "Watchlist and AML Screening",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Enter your details for verification",
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, thickness: 1),

                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Name Field ---
                        _buildLabel("Name *", textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration("Enter your full name"),
                          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter a name.' : null,
                        ),

                        const SizedBox(height: 20),

                        // --- Row: Date of Birth & Gender ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date of Birth
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Date of Birth", textColor),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _dobController,
                                    readOnly: true,
                                    onTap: () => _selectDate(context),
                                    style: TextStyle(color: textColor),
                                    decoration: inputDecoration("mm/dd/yyyy").copyWith(
                                      suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Gender
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel("Gender", textColor),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedGenderValue,
                                    isExpanded: true,
                                    style: TextStyle(color: textColor, fontSize: 14),
                                    icon: const Icon(Icons.keyboard_arrow_down),
                                    decoration: inputDecoration("Any"),
                                    items: genderOptions.map(((String, String) option) {
                                      return DropdownMenuItem<String>(
                                        value: option.$2,
                                        child: Text(option.$1),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) => setState(() => _selectedGenderValue = newValue),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
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
