import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/business_environment.dart';
import 'core/diagnostics/business_diagnostics.dart';

void main() {
  final diagnostics = BusinessDiagnostics.instance;

  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();

      final previousFlutterErrorHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        diagnostics.record(
          code: BusinessDiagnosticCode.flutterFrameworkError,
          source: BusinessDiagnosticSource.flutterFramework,
        );

        if (previousFlutterErrorHandler != null) {
          previousFlutterErrorHandler(details);
        } else {
          FlutterError.presentError(details);
        }
      };

      final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        diagnostics.record(
          code: BusinessDiagnosticCode.platformUncaughtError,
          source: BusinessDiagnosticSource.platformDispatcher,
        );

        if (previousPlatformErrorHandler != null) {
          return previousPlatformErrorHandler(error, stack);
        }
        return false;
      };

      unawaited(_bootstrap());
    },
    (Object error, StackTrace stack) {
      diagnostics.record(
        code: BusinessDiagnosticCode.zoneUncaughtError,
        source: BusinessDiagnosticSource.guardedZone,
      );

      Zone.root.handleUncaughtError(error, stack);
    },
  );
}

Future<void> _bootstrap() async {
  if (BusinessEnvironment.isConfigured) {
    await Supabase.initialize(
      url: BusinessEnvironment.supabaseUrl,
      publishableKey: BusinessEnvironment.publishableKey,
    );
  }

  runApp(const ProviderScope(child: ManasaknaBusinessApp()));
}
