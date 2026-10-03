import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/config/business_environment.dart';
import 'package:manasakna_business_console/core/diagnostics/business_diagnostics.dart';

void main() {
  test('Phase 11 diagnostics are bounded and privacy safe', () {
    final now = DateTime.utc(2026, 10, 1);
    final diagnostics = BusinessDiagnostics(capacity: 3, clock: () => now);

    for (var i = 0; i < 5; i++) {
      diagnostics.record(
        code: BusinessDiagnosticCode.flutterFrameworkError,
        source: BusinessDiagnosticSource.flutterFramework,
      );
    }

    final snapshot = diagnostics.snapshot();
    expect(snapshot, hasLength(3));
    expect(snapshot.first.sequence, 3);
    expect(snapshot.last.sequence, 5);
    expect(BusinessDiagnostics.persistsDiagnostics, isFalse);
    expect(BusinessDiagnostics.externalTelemetryEnabled, isFalse);

    final safe = snapshot.last.toSafeMap();
    expect(safe.keys.toSet(), <String>{
      'sequence',
      'code',
      'source',
      'occurredAtUtc',
    });
    expect(safe.toString(), isNot(contains('token')));
    expect(safe.toString(), isNot(contains('stack')));
    expect(safe.toString(), isNot(contains('message')));
  });

  test('global error capture is wired without external telemetry', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final diagnosticsSource = File(
      'lib/core/diagnostics/business_diagnostics.dart',
    ).readAsStringSync();

    expect(mainSource, contains('FlutterError.onError'));
    expect(mainSource, contains('PlatformDispatcher.instance.onError'));
    expect(mainSource, contains('runZonedGuarded'));
    expect(mainSource, contains('Zone.root.handleUncaughtError'));
    expect(mainSource, contains('return false'));
    expect(diagnosticsSource, isNot(contains('http://')));
    expect(diagnosticsSource, isNot(contains('https://')));
  });

  test('synthetic browser preview no longer exposes stale Phase 7 label', () {
    final source = File(
      'lib/features/commercial_mvp/presentation/commercial_mvp_page.dart',
    ).readAsStringSync();

    expect(
      BusinessEnvironment.phaseLabel,
      'Phase 11 — Preproduction Readiness',
    );
    expect(source, contains('معاينة ما قبل الإنتاج'));
    expect(source, isNot(contains('Phase 7 Preview')));
  });

  test('web bootstrap is accessible and removed after first Flutter frame', () {
    final index = File('web/index.html').readAsStringSync();
    final manifest =
        jsonDecode(File('web/manifest.json').readAsStringSync())
            as Map<String, dynamic>;

    expect(index, contains('role="status"'));
    expect(index, contains('aria-live="polite"'));
    expect(index, contains('flutter-first-frame'));
    expect(index, contains("document.getElementById('app-loading')?.remove()"));
    expect(manifest['name'], 'مناسكنا للأعمال');
    expect(manifest['dir'], 'rtl');
    expect(manifest['lang'], 'ar');

    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
    expect(bootstrap, contains("fontFallbackBaseUrl: 'fallback_fonts/'"));
    expect(
      File(
        'web/fallback_fonts/roboto/v32/KFOmCnqEu92Fr1Me4GZLCzYlKw.woff2',
      ).existsSync(),
      isTrue,
    );
    expect(File('web/fallback_fonts/roboto/OFL.txt').existsSync(), isTrue);
  });

  test('Arabic font is bundled locally for degraded web operation', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final designSource = File(
      'lib/core/design/manasakna_design_system.dart',
    ).readAsStringSync();
    expect(pubspec, contains('family: NotoSansArabic'));
    expect(pubspec, contains('assets/fonts/NotoSansArabic-Variable.ttf'));
    expect(designSource, contains("fontFamily: 'NotoSansArabic'"));
    expect(
      File('assets/fonts/NotoSansArabic-Variable.ttf').existsSync(),
      isTrue,
    );
    expect(File('assets/fonts/OFL.txt').existsSync(), isTrue);
  });

  test('Phase 10 provider authority remains closed during Phase 11', () {
    final manifest =
        jsonDecode(
              File(
                '../../docs/MANASAKNA_PHASE_10_PROVIDER_INTEGRATION_CONTRACT_V1.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(manifest['real_provider_activation_authorized'], isFalse);
    expect(manifest['shared_database_mutation'], isFalse);
    expect(manifest['direct_cross_plane_db_access'], isFalse);
    expect(manifest['production'], isFalse);
    expect(manifest['real_data'], isFalse);
  });
}
