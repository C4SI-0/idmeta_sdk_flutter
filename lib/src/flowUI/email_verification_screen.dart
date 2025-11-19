import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../verification/verification.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isOtpSent = false;
  String? _referenceOtp;

  final _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    _emailController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _otpFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid email address.")));
      return;
    }

    final get = context.read<Verification>();
    final refOtp = await get.sendEmailOtp(context, email: email);

    if (refOtp != null) {
      setState(() {
        _referenceOtp = refOtp;
        _isOtpSent = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _otpFocusNodes[0].requestFocus());
    } else if (mounted) {
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
    final success = await get.verifyEmailOtp(context, otp: otp, referenceId: _referenceOtp!);

    if (mounted && success) {
      get.nextScreen(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(get.errorMessage ?? 'Invalid OTP.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isOtpSent ? _buildOtpVerificationView() : _buildEmailInputView();
  }

  Widget _buildEmailInputView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email Address*', hintText: 'example@email.com'),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _sendOtp,
          child: const Text('Send Code'),
        ),
      ],
    );
  }

  Widget _buildOtpVerificationView() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text('Enter the 6-digit code sent to your email', style: TextStyle(fontSize: 18), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 50,
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
          child: const Text('Change Email Address'),
        ),
      ],
    );
  }
}
