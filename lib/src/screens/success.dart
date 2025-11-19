import 'package:flutter/material.dart';

/// A screen displayed to the user upon successful completion of the verification process.
///
/// This widget serves as the final step in the user flow, providing confirmation
/// that their submission was successful. It features a success message, a visual
/// indicator (an image), and a "Finish" button to close the SDK and return
/// to the host application.
class CompleteVerif extends StatelessWidget {
  /// Creates the [CompleteVerif] screen.
  const CompleteVerif({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WillPopScope(
        // Prevents the user from accidentally navigating back into the verification
        // flow using the system's back button after completion.
        // Returning `Future.value(false)` cancels the pop action.
        onWillPop: () async => false,
        child: Column(
          // Distribute the content evenly along the vertical axis.
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Title Text ---
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Verification Completed',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                )
              ],
            ),
            // --- Subtitle Text ---
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Thank you for completing the verification\nProcess',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.normal, fontSize: 15),
                ),
              ],
            ),
            // --- Success Image ---
            // Displays a visual confirmation. The asset is loaded from the package's assets.
            Image.asset(
              'assets/checked.png',
              package: 'idmeta_sdk_flutter', // Specifies that the asset belongs to this package.
              width: 150,
              height: 150,
            ),
            // --- Finish Button ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SizedBox(
                width: double.infinity, // Makes the button stretch to the screen width.
                child: TextButton(
                  onPressed: () {
                    // Pops the entire verification flow off the navigation stack.
                    // The value `true` is returned to the Future that was created when
                    // `IdmetaSdk.startVerification` was called, signaling a successful completion.
                    Navigator.of(context).pop(true);
                  },
                  // The style will be inherited from the dynamic theme applied by the `IdMeta` widget.
                  style: TextButton.styleFrom(),
                  child: const Text(
                    'Finish',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
