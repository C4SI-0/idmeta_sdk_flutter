import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'shared/face_verification_widget.dart';
import 'shared/submit_button.dart';
import 'shared/face_verification_webview.dart';

class ManualFormScreen extends StatefulWidget {
  final VoidCallback onBack;
  const ManualFormScreen({super.key, required this.onBack});
  @override
  State<ManualFormScreen> createState() => _ManualFormScreenState();
}

class _ManualFormScreenState extends State<ManualFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  String? _selectedSuffix = 'N/A';
  final List<String> _suffixes = const ['N/A', 'JR', 'SR', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV'];

  FaceVerificationStatus _faceStatus = FaceVerificationStatus.initial;
  String? _faceSessionId;
  String? _faceErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<Verification>();
      final data = provider.flowState.collectedData;
      _firstNameController.text = data['firstName'] ?? '';
      _lastNameController.text = data['lastName'] ?? '';
      _dobController.text = data['dob'] ?? '';
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(1900), lastDate: now);
    if (picked != null) {
      setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  Future<void> _handleFaceVerification() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
        context,
        MaterialPageRoute(
            builder: (_) => MultiProvider(
                  // ✨ THE FIX: Re-provide the necessary providers ✨
                  providers: [
                    // Pass the existing instance of VerificationProvider down to the new route
                    ChangeNotifierProvider.value(
                      value: context.read<Verification>(),
                    ),
                  ],
                  child: const FaceVerificationWebView(),
                )));
    if (result != null && mounted) {
      final sessionId = result['session_id'];
      if (sessionId != null && sessionId is String && sessionId.isNotEmpty) {
        setState(() {
          _faceStatus = FaceVerificationStatus.success;
          _faceSessionId = sessionId;
        });
      } else {
        setState(() {
          _faceStatus = FaceVerificationStatus.failed;
          _faceErrorMessage = result['message']?.toString() ?? "Liveness verification failed";
        });
      }
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all required fields.')));
      return;
    }
    if (_faceStatus != FaceVerificationStatus.success || _faceSessionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete face verification first.')));
      return;
    }

    final pcnFormData = {
      "first_name": _firstNameController.text,
      "middle_name": _middleNameController.text.isNotEmpty ? _middleNameController.text : null,
      "last_name": _lastNameController.text,
      "suffix": _selectedSuffix != 'N/A' ? _selectedSuffix : null,
      "birth_date": _dobController.text,
    };

    final provider = context.read<Verification>();
    final success = await provider.submitPhilSysData(context, faceLivenessSessionId: _faceSessionId!, pcnFormData: pcnFormData);

    if (success && mounted) {
      provider.nextScreen(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Verification failed.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Align(
              alignment: Alignment.topLeft,
              child: TextButton.icon(icon: const Icon(Icons.arrow_back), label: const Text('Back to selection'), onPressed: widget.onBack)),
          const SizedBox(height: 24),
          const Text('Step 1: Personal Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name *'),
              validator: (v) => (v?.isEmpty ?? true) ? "Required" : null),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: TextFormField(controller: _middleNameController, decoration: const InputDecoration(labelText: 'Middle Name'))),
              const SizedBox(width: 16),
              Expanded(child: _buildSuffixDropdown()),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name *'),
              validator: (v) => (v?.isEmpty ?? true) ? "Required" : null),
          const SizedBox(height: 20),
          TextFormField(
              controller: _dobController,
              readOnly: true,
              onTap: _selectDate,
              decoration: InputDecoration(labelText: 'Date of Birth *', suffixIcon: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.secondary)),
              validator: (v) => (v?.isEmpty ?? true) ? "Required" : null),
          const SizedBox(height: 40),
          const Text('Step 2: Identity Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          FaceVerificationWidget(status: _faceStatus, errorMessage: _faceErrorMessage, onVerify: _handleFaceVerification),
          const SizedBox(height: 40),
          SubmitButton(isEnabled: _faceStatus == FaceVerificationStatus.success, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _buildSuffixDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSuffix,
      items: _suffixes.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
      onChanged: (newValue) => setState(() => _selectedSuffix = newValue),
      decoration: const InputDecoration(labelText: 'Suffix'),
    );
  }
}
