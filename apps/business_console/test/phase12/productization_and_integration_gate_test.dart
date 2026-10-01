import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/official_external_integrations/domain/phase12_external_integration_readiness.dart';
import 'package:manasakna_business_console/features/official_external_integrations/domain/phase12_integration_gate.dart';

void main() {
  test('P12-F stays closed until P12-E productization gate passes', () {
    const admission = Phase12IntegrationAdmission(
      productizationGate: Phase12ProductizationGate.pending,
      environment: Phase12IntegrationEnvironment.sandbox,
      hasRealUserData: false,
      usesSharedDatabase: false,
      usesProductionCredential: false,
    );

    expect(admission.isAdmitted, isFalse);
    expect(admission.reason, 'P12_E_PRODUCTIZATION_GATE_NOT_PASSED');
  });

  test('only non-production integration is admitted after P12-E', () {
    const sandbox = Phase12IntegrationAdmission(
      productizationGate: Phase12ProductizationGate.passed,
      environment: Phase12IntegrationEnvironment.sandbox,
      hasRealUserData: false,
      usesSharedDatabase: false,
      usesProductionCredential: false,
    );
    const production = Phase12IntegrationAdmission(
      productizationGate: Phase12ProductizationGate.passed,
      environment: Phase12IntegrationEnvironment.production,
      hasRealUserData: false,
      usesSharedDatabase: false,
      usesProductionCredential: false,
    );

    expect(sandbox.isAdmitted, isTrue);
    expect(production.isAdmitted, isFalse);
  });

  test(
    'external integration registry exposes only verified non-production evidence',
    () {
      expect(phase12ExternalIntegrationReadiness, hasLength(5));
      expect(phase12ExternalIntegrationsTruthful, isTrue);

      final dataPlane = phase12ExternalIntegrationReadiness.singleWhere(
        (item) => item.id == 'business-data-plane',
      );
      expect(dataPlane.verifiedNonProduction, isTrue);

      final deferred = phase12ExternalIntegrationReadiness.where(
        (item) =>
            item.state ==
            Phase12ExternalIntegrationState.deferredNoSandboxAccess,
      );
      expect(deferred, hasLength(4));
      expect(
        phase12ExternalIntegrationReadiness.every(
          (item) => !item.productionEnabled && !item.realUserDataEnabled,
        ),
        isTrue,
      );
    },
  );

  test('Phase12 user-visible operations surface has no MVP/preview label', () {
    final source = File(
      'lib/features/commercial_mvp/presentation/commercial_operations_center.dart',
    ).readAsStringSync();

    expect(source, contains('مركز عمليات العمرة'));
    expect(source, contains('الوحدات التشغيلية'));
    expect(source, isNot(contains('خريطة MVP التشغيلية')));
    expect(source, isNot(contains('معاينة ما قبل الإنتاج')));
    expect(source, isNot(contains('Phase 7 Preview')));
  });

  test('Phase12 business app routes synthetic mode to productized surface', () {
    final source = File('lib/app.dart').readAsStringSync();
    expect(source, contains('CommercialOperationsSyntheticPage'));
    expect(source, isNot(contains('CommercialMvpBrowserPreviewPage')));
  });

  test('Business web shell owns the real mobile viewport', () {
    final source = File('web/index.html').readAsStringSync();
    expect(
      source,
      contains(
        '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
      ),
    );
  });
}
