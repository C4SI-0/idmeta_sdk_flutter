import 'package:flutter/material.dart';
import 'package:idmeta_sdk_flutter/src/verification/verification.dart';
import 'package:provider/provider.dart';

class SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isEnabled;

  const SubmitButton({
    super.key,
    required this.onPressed,
    this.text = 'Next',
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<Verification>().isLoading;
    final canPress = isEnabled && !isLoading;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      onPressed: canPress ? onPressed : null,
      child: Text(text),
    );
  }
}
