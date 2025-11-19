import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable loading indicator widget displayed during verification processes.
///
/// This widget features a central icon with a shimmer effect and a "Verifying..."
/// text label below it. It's designed to be shown inside a dialog or overlay
/// to indicate that a background task is in progress.
class Loader extends StatelessWidget {
  /// Creates a [Loader] widget.
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        // Use min to make the column only as tall as its children.
        mainAxisSize: MainAxisSize.min,
        children: [
          // The Shimmer widget from the `shimmer` package provides an animated
          // "shining" effect, often used for loading placeholders.
          Shimmer(
            // A gradient that moves across the child widget.
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey, Colors.white],
              stops: [0.4, 0.5, 0.6], // Defines the gradient transition points.
            ),
            // The duration for one shimmer animation cycle.
            period: Duration(seconds: 2),
            child: Icon(
              Icons.fact_check, // An icon representing verification.
              size: 64,
              color: Colors.white, // The base color of the icon.
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Verifying...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              // `TextDecoration.none` is used to ensure no underlines appear,
              // which can sometimes happen in certain widget tree configurations.
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// A utility function to display a full-screen, non-dismissible loading dialog.
///
/// This function presents the [Loader] widget within a [showDialog] call,
/// preventing the user from interacting with the underlying UI until the
/// loader is explicitly hidden via [hideLoader].
///
/// The [context] is the `BuildContext` from which to show the dialog.
void showLoader(BuildContext context) {
  showDialog(
    context: context,
    // `barrierDismissible: false` prevents the dialog from being closed by
    // tapping the overlay.
    barrierDismissible: false,
    // The builder returns the Loader widget to be displayed.
    builder: (_) => const Loader(),
  );
}

/// A utility function to hide the most recently displayed dialog.
///
/// This is intended to be used to dismiss the dialog shown by [showLoader].
/// It includes a check to ensure that a route can be popped before attempting
/// to do so, preventing potential errors.
///
/// The [context] is the `BuildContext` from which to pop the dialog's route.
void hideLoader(BuildContext context) {
  // `rootNavigator: true` ensures that we are trying to pop from the top-most
  // navigator, which is where dialogs are typically shown.
  // The `canPop()` check prevents an exception if no route is available to be popped.
  if (Navigator.of(context, rootNavigator: true).canPop()) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
