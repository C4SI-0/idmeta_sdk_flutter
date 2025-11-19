import 'package:flutter/material.dart';

enum FaceVerificationStatus { initial, success, failed }

class FaceVerificationWidget extends StatelessWidget {
  final FaceVerificationStatus status;
  final String? errorMessage;
  final VoidCallback onVerify;

  const FaceVerificationWidget({
    super.key,
    required this.status,
    this.errorMessage,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    if (status == FaceVerificationStatus.success) {
      return _buildSuccessView();
    } else {
      return _buildInitialView(context);
    }
  }

  Widget _buildInitialView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildVerificationOption(
          context: context,
          icon: Icons.face_retouching_natural,
          label: 'Face Verification',
          subtitle: 'Use facial recognition to verify',
          onTap: onVerify,
        ),
        if (status == FaceVerificationStatus.failed)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(
              errorMessage ?? "An unknown error occurred.",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade300),
        color: Colors.green.withOpacity(0.1),
      ),
      child: Column(
        children: [
          _buildSuccessRow(Icons.check_circle, "Selfie Captured", Colors.green),
          const SizedBox(height: 8),
          _buildSuccessRow(Icons.check_circle, "Liveness Verification Completed", Colors.green),
        ],
      ),
    );
  }

  Widget _buildSuccessRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildVerificationOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.primaryColor), color: theme.colorScheme.secondary),
        child: Row(
          children: [
            Icon(icon, size: 40, color: theme.primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.primaryColor)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
