/// A library for integrating with the Idmeta verification SDK in Flutter applications.
library idmeta_sdk_flutter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/api/service.dart';
import 'src/core/repository.dart';
import 'src/idmeta.dart';
import 'src/verification/verification.dart';
export 'src/widgets/button.dart';

/// The main class for interacting with the Idmeta SDK.
///
/// This class provides a static method to start the user verification process.
class IdmetaSdk {
  /// Starts the user verification process.
  ///
  /// This method pushes a new route to the navigator, which contains the
  /// Idmeta verification flow. It sets up the necessary providers for
  /// dependency injection.
  ///
  /// The [context] is the `BuildContext` from which to push the new route.
  /// The [userToken] is the authentication token for the user.
  /// The [templateId] is the specific verification template to be used.
  /// The [useRootNavigator] determines whether to use the root navigator for
  /// pushing the new route.
  ///
  /// Returns a `Future` that completes with a value of type [T] when the
  /// verification flow is finished.
  static Future<T?> startVerification<T>({
    required BuildContext context,
    required String userToken,
    required String templateId,
    bool useRootNavigator = false,
  }) {
    return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            // Provides the ApiService to the rest of the widget tree.
            Provider(create: (_) => ApiService()),
            // Creates a VerificationRepository that depends on ApiService.
            ProxyProvider<ApiService, VerificationRepository>(
              update: (_, apiService, __) => VerificationRepository(apiService: apiService),
            ),
            // Creates and provides the Verification notifier, initializing it with necessary data.
            ChangeNotifierProxyProvider<VerificationRepository, Verification>(
              create: (context) => Verification(
                repository: context.read<VerificationRepository>(),
                apiService: context.read<ApiService>(),
              )..initialize(userToken: userToken, templateId: templateId),
              update: (_, repository, previousProvider) => previousProvider!,
            ),
          ],
          // The root widget of the verification flow.
          child: const IdMeta(),
        ),
      ),
    );
  }
}
