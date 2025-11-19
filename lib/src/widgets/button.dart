import 'package:flutter/material.dart';
import '../../idmeta_sdk.dart';

/// A pre-configured button widget to initiate the Idmeta verification process.
///
/// This widget simplifies the process of starting the verification flow. Instead of
/// manually calling `IdmetaSdk.startVerification`, you can use this button
/// directly in your UI. It wraps an [ElevatedButton] and triggers the
/// verification flow when pressed.
class IdmetaVerificationButton extends StatelessWidget {
  /// The authentication token for the user undergoing verification.
  /// This is required to identify the user session.
  final String userToken;

  /// The unique identifier for the verification template to be used.
  /// This determines the sequence of steps in the verification flow.
  final String templateId;

  /// The widget to display inside the button.
  ///
  /// If null, a default [Text] widget with the text 'Start Verification' will be used.
  final Widget? child;

  /// The style to be applied to the button.
  ///
  /// This allows for customization of the button's appearance, such as colors,
  /// padding, and shape, using [ButtonStyle]. If null, the default
  /// [ElevatedButton] style from the current theme will be used.
  final ButtonStyle? style;

  /// Creates an Idmeta verification button.
  ///
  /// The [userToken] and [templateId] parameters are required.
  const IdmetaVerificationButton({
    super.key,
    required this.userToken,
    required this.templateId,
    this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    // Returns an ElevatedButton which is a standard Material Design button.
    return ElevatedButton(
      // Apply the custom style if provided.
      style: style,
      // The onPressed callback is where the magic happens.
      // It calls the static startVerification method from the IdmetaSdk.
      onPressed: () {
        IdmetaSdk.startVerification(
          context: context,
          userToken: userToken,
          templateId: templateId,
        );
      },
      // Use the provided child widget, or a default Text widget if child is null.
      child: child ?? const Text('Start Verification'),
    );
  }
}
