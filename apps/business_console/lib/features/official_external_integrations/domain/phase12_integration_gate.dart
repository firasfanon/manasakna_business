enum Phase12ProductizationGate { pending, passed, failed }

enum Phase12IntegrationEnvironment {
  synthetic,
  sandbox,
  nonProduction,
  production,
}

class Phase12IntegrationAdmission {
  const Phase12IntegrationAdmission({
    required this.productizationGate,
    required this.environment,
    required this.hasRealUserData,
    required this.usesSharedDatabase,
    required this.usesProductionCredential,
  });

  final Phase12ProductizationGate productizationGate;
  final Phase12IntegrationEnvironment environment;
  final bool hasRealUserData;
  final bool usesSharedDatabase;
  final bool usesProductionCredential;

  bool get isAdmitted {
    if (productizationGate != Phase12ProductizationGate.passed) return false;
    if (environment == Phase12IntegrationEnvironment.production) return false;
    if (hasRealUserData) return false;
    if (usesSharedDatabase) return false;
    if (usesProductionCredential) return false;
    return environment == Phase12IntegrationEnvironment.sandbox ||
        environment == Phase12IntegrationEnvironment.nonProduction ||
        environment == Phase12IntegrationEnvironment.synthetic;
  }

  String get reason {
    if (productizationGate != Phase12ProductizationGate.passed) {
      return 'P12_E_PRODUCTIZATION_GATE_NOT_PASSED';
    }
    if (environment == Phase12IntegrationEnvironment.production) {
      return 'PRODUCTION_ENDPOINT_PROHIBITED';
    }
    if (hasRealUserData) return 'REAL_USER_DATA_PROHIBITED';
    if (usesSharedDatabase) return 'SHARED_DATABASE_PROHIBITED';
    if (usesProductionCredential) return 'PRODUCTION_CREDENTIAL_PROHIBITED';
    return 'ADMITTED_NON_PRODUCTION_INTEGRATION';
  }
}
