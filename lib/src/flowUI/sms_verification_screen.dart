import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../verification/verification.dart';

class SmsVerificationScreen extends StatefulWidget {
  const SmsVerificationScreen({super.key});
  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  bool _isOtpSent = false;
  String? _referenceId;

  final _phoneController = TextEditingController(text: "");
  final _countryCodeController = TextEditingController(text: "");
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _phoneController.dispose();
    _countryCodeController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.isEmpty || _countryCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields.")));
      return;
    }

    final get = context.read<Verification>();
    final refId = await get.sendSmsOtp(
      context,
      phoneNumber: _phoneController.text,
      countryCode: _countryCodeController.text,
    );
    if (!mounted) return;

    if (refId != null) {
      setState(() {
        _referenceId = refId;
        _isOtpSent = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFocusNodes[0].requestFocus();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Failed to send OTP.')));
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter the complete 6-digit code.")));
      return;
    }

    final get = context.read<Verification>();
    final success = await get.verifySmsOtp(context, otp: otp, referenceId: _referenceId!);
    if (!mounted) return;

    if (success) {
      get.nextScreen(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Invalid OTP.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isOtpSent ? _buildOtpVerificationView() : _buildPhoneInputView();
  }

  Widget _buildPhoneInputView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        TextFormField(
          controller: _countryCodeController,
          decoration: const InputDecoration(labelText: 'Country Code*', hintText: 'e.g. +62'),
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\+?\d*'))],
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone Number*', hintText: 'Number without country code'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _sendOtp,
          child: const Text('Send OTP'),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text('Enter the 6-digit code sent to your phone', style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 40,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
                style: const TextStyle(fontSize: 24),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _verifyOtp,
          child: const Text('Verify'),
        ),
        TextButton(
          onPressed: () => setState(() => _isOtpSent = false),
          child: const Text('Change Phone Number'),
        ),
      ],
    );
  }
}
