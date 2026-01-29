import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:provider/provider.dart';

class BusinessAmlScreen extends StatefulWidget {
  const BusinessAmlScreen({super.key});
  @override
  State<BusinessAmlScreen> createState() => _BusinessAmlScreenState();
}

class _BusinessAmlScreenState extends State<BusinessAmlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final get = context.read<Verification>();

      // 1. Register the submit function to the Sticky Footer
      get.setContinueAction(_submitForm);

      // 2. Restore Data (if user navigates back)
      final data = get.flowState.collectedData;
      _businessNameController.text = data['business_name'] ?? '';
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final get = context.read<Verification>();

    // 3. Save Data Locally before API call
    get.updateStepData({
      'business_name': _businessNameController.text,
    });

    final success = await get.submitBusinessAml(context, businessName: _businessNameController.text);

    if (!mounted) return;
    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Verification failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<Verification>().designSettings?.settings;
    final textColor = settings?.textColor ?? Colors.black;
    final secondaryColor = settings?.secondaryColor ?? Colors.blue;

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
                            Icon(Icons.store_mall_directory_outlined, size: 22, color: textColor),
                            const SizedBox(width: 8),
                            Text(
                              "Business AML Check",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Verify business entity details",
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
                        _buildLabel("Business Name *", textColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _businessNameController,
                          style: TextStyle(color: textColor),
                          decoration: inputDecoration("Enter registered business name"),
                          validator: (value) => (value?.trim().isEmpty ?? true) ? 'Please enter the business name.' : null,
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
