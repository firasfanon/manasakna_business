enum Phase12ExternalIntegrationState {
  verifiedNonProduction,
  deferredNoSandboxAccess,
}

class Phase12ExternalIntegrationReadiness {
  const Phase12ExternalIntegrationReadiness({
    required this.id,
    required this.labelAr,
    required this.state,
    required this.reasonAr,
  });

  final String id;
  final String labelAr;
  final Phase12ExternalIntegrationState state;
  final String reasonAr;

  bool get productionEnabled => false;
  bool get realUserDataEnabled => false;

  bool get verifiedNonProduction =>
      state == Phase12ExternalIntegrationState.verifiedNonProduction;
}

const phase12ExternalIntegrationReadiness = <Phase12ExternalIntegrationReadiness>[
  Phase12ExternalIntegrationReadiness(
    id: 'business-data-plane',
    labelAr: 'بيانات الأعمال',
    state: Phase12ExternalIntegrationState.verifiedNonProduction,
    reasonAr:
        'تم التحقق من Supabase غير الإنتاجي: migrations وRPC والعزل تعمل، واختبارات التكامل تنتهي بـ rollback دون بيانات دائمة.',
  ),
  Phase12ExternalIntegrationReadiness(
    id: 'government-nusuk',
    labelAr: 'الحكومة / Nusuk',
    state: Phase12ExternalIntegrationState.deferredNoSandboxAccess,
    reasonAr: 'مؤجل — لا تتوفر بيئة اختبار رسمية أو بيانات اعتماد Sandbox.',
  ),
  Phase12ExternalIntegrationReadiness(
    id: 'payment',
    labelAr: 'الدفع',
    state: Phase12ExternalIntegrationState.deferredNoSandboxAccess,
    reasonAr: 'مؤجل — لا تتوفر بيانات اعتماد Payment Sandbox.',
  ),
  Phase12ExternalIntegrationReadiness(
    id: 'messaging',
    labelAr: 'المراسلة',
    state: Phase12ExternalIntegrationState.deferredNoSandboxAccess,
    reasonAr: 'مؤجل — لا تتوفر بيانات اعتماد Messaging Sandbox.',
  ),
  Phase12ExternalIntegrationReadiness(
    id: 'travel-inventory',
    labelAr: 'السفر والمخزون',
    state: Phase12ExternalIntegrationState.deferredNoSandboxAccess,
    reasonAr: 'مؤجل — لا تتوفر بيئة Travel/Inventory Sandbox.',
  ),
];

bool get phase12ExternalIntegrationsTruthful {
  final verified = phase12ExternalIntegrationReadiness
      .where((item) => item.verifiedNonProduction)
      .toList(growable: false);
  final deferred = phase12ExternalIntegrationReadiness
      .where(
        (item) =>
            item.state ==
            Phase12ExternalIntegrationState.deferredNoSandboxAccess,
      )
      .toList(growable: false);

  return verified.length == 1 &&
      verified.single.id == 'business-data-plane' &&
      deferred.length == 4 &&
      phase12ExternalIntegrationReadiness.every(
        (item) =>
            !item.productionEnabled &&
            !item.realUserDataEnabled &&
            item.reasonAr.trim().isNotEmpty,
      );
}
