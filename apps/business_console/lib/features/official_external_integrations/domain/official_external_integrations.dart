import 'dart:async';

const phase10IntegrationContractVersion = 'manasakna-provider-integration-v1';
const phase10ExecutionMode = 'synthetic_non_production_only';
const phase10SyntheticWebhookSignature = 'synthetic-signature-v1';

const phase10ForbiddenPayloadKeys = <String>{
  'api_key',
  'authorization',
  'card_number',
  'client_secret',
  'cvv',
  'full_name',
  'passport_reference',
  'password',
  'service_role',
  'secret',
  'token',
};

const phase10AllowedResponseKeys = <String>{
  'amount_minor',
  'availability_count',
  'currency',
  'delivery_state',
  'reference',
  'source_note',
  'status',
};

enum ExternalProviderClass { officialRegulatory, messaging, payment, travel }

enum ProviderAuthority { government, platformOperational, commercialProvider }

enum ProviderAvailability { available, degraded, unavailable }

enum ProviderAuditOutcome { allowed, replayed, denied, failed }

extension ExternalProviderClassCode on ExternalProviderClass {
  String get code => switch (this) {
    ExternalProviderClass.officialRegulatory => 'official_regulatory',
    ExternalProviderClass.messaging => 'messaging',
    ExternalProviderClass.payment => 'payment',
    ExternalProviderClass.travel => 'travel',
  };
}

extension ProviderAuthorityCode on ProviderAuthority {
  String get code => switch (this) {
    ProviderAuthority.government => 'government',
    ProviderAuthority.platformOperational => 'platform_operational',
    ProviderAuthority.commercialProvider => 'commercial_provider',
  };
}

class ProviderDescriptor {
  const ProviderDescriptor({
    required this.providerId,
    required this.providerClass,
    required this.authority,
    required this.sourceOfTruthDomain,
    required this.allowedOperations,
    this.realActivationAuthorized = false,
  });

  final String providerId;
  final ExternalProviderClass providerClass;
  final ProviderAuthority authority;
  final String sourceOfTruthDomain;
  final Set<String> allowedOperations;
  final bool realActivationAuthorized;

  void validate() {
    if (providerId.trim().isEmpty ||
        sourceOfTruthDomain.trim().isEmpty ||
        allowedOperations.isEmpty) {
      throw const FormatException('INVALID_PROVIDER_DESCRIPTOR');
    }
    if (realActivationAuthorized) {
      throw const FormatException('REAL_PROVIDER_ACTIVATION_PROHIBITED');
    }
    if (providerClass == ExternalProviderClass.officialRegulatory &&
        authority != ProviderAuthority.government) {
      throw const FormatException(
        'OFFICIAL_PROVIDER_AUTHORITY_MUST_BE_GOVERNMENT',
      );
    }
  }
}

class ProviderResiliencePolicy {
  const ProviderResiliencePolicy({
    this.timeout = const Duration(seconds: 2),
    this.maxAttempts = 2,
    this.explicitUnavailableFallback = true,
  });

  final Duration timeout;
  final int maxAttempts;
  final bool explicitUnavailableFallback;

  void validate() {
    if (timeout <= Duration.zero || maxAttempts < 1 || maxAttempts > 3) {
      throw const FormatException('INVALID_PROVIDER_RESILIENCE_POLICY');
    }
  }
}

class ProviderRequest {
  const ProviderRequest({
    required this.contractVersion,
    required this.requestId,
    required this.idempotencyKey,
    required this.requestedAt,
    required this.providerId,
    required this.operation,
    required this.subjectRef,
    required this.dataClassification,
    required this.syntheticFixture,
    required this.payload,
  });

  final String contractVersion;
  final String requestId;
  final String idempotencyKey;
  final DateTime requestedAt;
  final String providerId;
  final String operation;
  final String subjectRef;
  final String dataClassification;
  final bool syntheticFixture;
  final Map<String, Object?> payload;

  void validateEnvelope() {
    if (contractVersion != phase10IntegrationContractVersion) {
      throw const FormatException('UNSUPPORTED_PROVIDER_CONTRACT_VERSION');
    }
    if (requestId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty ||
        providerId.trim().isEmpty ||
        operation.trim().isEmpty ||
        subjectRef.trim().isEmpty) {
      throw const FormatException('INVALID_PROVIDER_REQUEST_IDENTITY');
    }
    if (!requestedAt.isUtc) {
      throw const FormatException('PROVIDER_REQUEST_TIME_MUST_BE_UTC');
    }
    if (!syntheticFixture) {
      throw const FormatException('REAL_OR_UNMARKED_PROVIDER_DATA_PROHIBITED');
    }
    if (!const {
      'synthetic_test',
      'traveler_safe',
      'operational_safe',
    }.contains(dataClassification)) {
      throw const FormatException('UNSUPPORTED_PROVIDER_DATA_CLASSIFICATION');
    }
    _assertNoForbiddenKeys(payload);
  }

  String get replayFingerprint =>
      '$providerId|$operation|$subjectRef|$requestId';
}

class ProviderProvenance {
  const ProviderProvenance({
    required this.providerId,
    required this.authority,
    required this.observedAt,
    required this.synthetic,
    required this.authoritativeSourceClaim,
  });

  final String providerId;
  final ProviderAuthority authority;
  final DateTime observedAt;
  final bool synthetic;
  final bool authoritativeSourceClaim;

  void validate() {
    if (providerId.trim().isEmpty || !observedAt.isUtc) {
      throw const FormatException('INVALID_PROVIDER_PROVENANCE');
    }
    if (!synthetic || authoritativeSourceClaim) {
      throw const FormatException(
        'SYNTHETIC_PROVENANCE_MUST_NOT_CLAIM_AUTHORITY',
      );
    }
  }
}

class ProviderResponse {
  const ProviderResponse({
    required this.contractVersion,
    required this.requestId,
    required this.eventId,
    required this.providerId,
    required this.observedAt,
    required this.availability,
    required this.payload,
    required this.provenance,
  });

  final String contractVersion;
  final String requestId;
  final String eventId;
  final String providerId;
  final DateTime observedAt;
  final ProviderAvailability availability;
  final Map<String, Object?> payload;
  final ProviderProvenance provenance;

  void validateAgainst(ProviderRequest request, ProviderDescriptor descriptor) {
    if (contractVersion != phase10IntegrationContractVersion ||
        requestId != request.requestId ||
        providerId != request.providerId ||
        providerId != descriptor.providerId ||
        eventId.trim().isEmpty ||
        !observedAt.isUtc) {
      throw const FormatException('INVALID_PROVIDER_RESPONSE_CORRELATION');
    }
    provenance.validate();
    if (provenance.providerId != providerId ||
        provenance.authority != descriptor.authority ||
        provenance.observedAt != observedAt) {
      throw const FormatException('PROVIDER_PROVENANCE_MISMATCH');
    }
    final unapproved = payload.keys.toSet().difference(
      phase10AllowedResponseKeys,
    );
    if (unapproved.isNotEmpty) {
      throw FormatException(
        'UNAPPROVED_PROVIDER_RESPONSE_FIELD:${unapproved.first}',
      );
    }
    _assertNoForbiddenKeys(payload);
  }

  factory ProviderResponse.unavailable({
    required ProviderRequest request,
    required ProviderDescriptor descriptor,
    required DateTime observedAt,
  }) {
    final at = observedAt.toUtc();
    return ProviderResponse(
      contractVersion: phase10IntegrationContractVersion,
      requestId: request.requestId,
      eventId: 'synthetic-unavailable:${request.requestId}',
      providerId: descriptor.providerId,
      observedAt: at,
      availability: ProviderAvailability.unavailable,
      payload: const {
        'status': 'unavailable',
        'source_note': 'synthetic_fail_closed',
      },
      provenance: ProviderProvenance(
        providerId: descriptor.providerId,
        authority: descriptor.authority,
        observedAt: at,
        synthetic: true,
        authoritativeSourceClaim: false,
      ),
    );
  }
}

abstract interface class ProviderAdapter {
  ProviderDescriptor get descriptor;
  Future<ProviderResponse> execute(ProviderRequest request);
}

abstract base class SyntheticProviderAdapter implements ProviderAdapter {
  SyntheticProviderAdapter({DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final DateTime Function() clock;
  int callCount = 0;

  Map<String, Object?> buildPayload(ProviderRequest request);

  @override
  Future<ProviderResponse> execute(ProviderRequest request) async {
    callCount += 1;
    final at = clock().toUtc();
    return ProviderResponse(
      contractVersion: phase10IntegrationContractVersion,
      requestId: request.requestId,
      eventId: '${descriptor.providerId}:${request.requestId}',
      providerId: descriptor.providerId,
      observedAt: at,
      availability: ProviderAvailability.available,
      payload: Map.unmodifiable(buildPayload(request)),
      provenance: ProviderProvenance(
        providerId: descriptor.providerId,
        authority: descriptor.authority,
        observedAt: at,
        synthetic: true,
        authoritativeSourceClaim: false,
      ),
    );
  }
}

final class SyntheticOfficialRegulatoryAdapter
    extends SyntheticProviderAdapter {
  SyntheticOfficialRegulatoryAdapter({super.clock});

  @override
  ProviderDescriptor get descriptor => const ProviderDescriptor(
    providerId: 'official-regulatory-synthetic-v1',
    providerClass: ExternalProviderClass.officialRegulatory,
    authority: ProviderAuthority.government,
    sourceOfTruthDomain: 'official_regulatory_external',
    allowedOperations: {'official.status.read', 'hajj.status.read'},
  );

  @override
  Map<String, Object?> buildPayload(ProviderRequest request) => const {
    'status': 'synthetic_only',
    'source_note': 'not_an_official_record',
  };
}

final class SyntheticMessagingAdapter extends SyntheticProviderAdapter {
  SyntheticMessagingAdapter({super.clock});

  @override
  ProviderDescriptor get descriptor => const ProviderDescriptor(
    providerId: 'messaging-synthetic-v1',
    providerClass: ExternalProviderClass.messaging,
    authority: ProviderAuthority.platformOperational,
    sourceOfTruthDomain: 'messaging_external',
    allowedOperations: {'message.preview', 'message.status.synthetic'},
  );

  @override
  Map<String, Object?> buildPayload(ProviderRequest request) => const {
    'status': 'synthetic_only',
    'delivery_state': 'preview_not_delivered',
  };
}

final class SyntheticPaymentAdapter extends SyntheticProviderAdapter {
  SyntheticPaymentAdapter({super.clock});

  @override
  ProviderDescriptor get descriptor => const ProviderDescriptor(
    providerId: 'payment-synthetic-v1',
    providerClass: ExternalProviderClass.payment,
    authority: ProviderAuthority.commercialProvider,
    sourceOfTruthDomain: 'payment_external',
    allowedOperations: {'payment.intent.preview', 'payment.status.synthetic'},
  );

  @override
  Map<String, Object?> buildPayload(ProviderRequest request) => {
    'status': 'synthetic_no_charge',
    'amount_minor': request.payload['amount_minor'] ?? 0,
    'currency': request.payload['currency'] ?? 'USD',
    'reference': 'PAY-SYN-${request.requestId}',
  };
}

final class SyntheticTravelProviderAdapter extends SyntheticProviderAdapter {
  SyntheticTravelProviderAdapter({super.clock});

  @override
  ProviderDescriptor get descriptor => const ProviderDescriptor(
    providerId: 'travel-synthetic-v1',
    providerClass: ExternalProviderClass.travel,
    authority: ProviderAuthority.commercialProvider,
    sourceOfTruthDomain: 'travel_provider_external',
    allowedOperations: {
      'travel.availability.preview',
      'travel.booking_status.synthetic',
    },
  );

  @override
  Map<String, Object?> buildPayload(ProviderRequest request) => const {
    'status': 'synthetic_availability',
    'availability_count': 2,
    'source_note': 'no_live_inventory_call',
  };
}

class ProviderAdapterRegistry {
  ProviderAdapterRegistry(Iterable<ProviderAdapter> adapters)
    : _adapters = {
        for (final adapter in adapters) adapter.descriptor.providerId: adapter,
      };

  factory ProviderAdapterRegistry.synthetic({DateTime Function()? clock}) =>
      ProviderAdapterRegistry([
        SyntheticOfficialRegulatoryAdapter(clock: clock),
        SyntheticMessagingAdapter(clock: clock),
        SyntheticPaymentAdapter(clock: clock),
        SyntheticTravelProviderAdapter(clock: clock),
      ]);

  final Map<String, ProviderAdapter> _adapters;

  ProviderAdapter require(String providerId) {
    final adapter = _adapters[providerId];
    if (adapter == null) {
      throw const FormatException('UNKNOWN_PROVIDER');
    }
    return adapter;
  }

  List<ProviderDescriptor> get descriptors => _adapters.values
      .map((adapter) => adapter.descriptor)
      .toList(growable: false);
}

class ProviderAdmissionGate {
  const ProviderAdmissionGate();

  ProviderDescriptor admit(
    ProviderRequest request,
    ProviderAdapterRegistry registry,
  ) {
    request.validateEnvelope();
    final descriptor = registry.require(request.providerId).descriptor;
    descriptor.validate();
    if (!descriptor.allowedOperations.contains(request.operation)) {
      throw const FormatException('PROVIDER_OPERATION_NOT_ALLOWED');
    }
    if (request.operation.startsWith('hajj.') &&
        (descriptor.providerClass != ExternalProviderClass.officialRegulatory ||
            request.operation != 'hajj.status.read')) {
      throw const FormatException('HAJJ_SOVEREIGN_MUTATION_PROHIBITED');
    }
    if (request.operation.contains('.write') ||
        request.operation.contains('.manage') ||
        request.operation.contains('.submit')) {
      throw const FormatException('PROVIDER_MUTATION_OPERATION_PROHIBITED');
    }
    return descriptor;
  }
}

class ProviderIdempotencyRecord {
  const ProviderIdempotencyRecord({
    required this.fingerprint,
    required this.response,
  });

  final String fingerprint;
  final ProviderResponse response;
}

class MemoryProviderIdempotencyStore {
  final Map<String, ProviderIdempotencyRecord> _records = {};

  ProviderIdempotencyRecord? read(String key) => _records[key];

  void write(String key, ProviderIdempotencyRecord record) {
    _records[key] = record;
  }
}

class ProviderAuditEvent {
  const ProviderAuditEvent({
    required this.requestId,
    required this.providerId,
    required this.operation,
    required this.outcome,
    required this.reason,
  });

  final String requestId;
  final String providerId;
  final String operation;
  final ProviderAuditOutcome outcome;
  final String reason;
}

class MemoryProviderAuditSink {
  final List<ProviderAuditEvent> events = [];

  void record(ProviderAuditEvent event) => events.add(event);
}

class ProviderIntegrationClient {
  ProviderIntegrationClient({
    required this.registry,
    required this.idempotencyStore,
    required this.auditSink,
    this.admissionGate = const ProviderAdmissionGate(),
    this.policy = const ProviderResiliencePolicy(),
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final ProviderAdapterRegistry registry;
  final MemoryProviderIdempotencyStore idempotencyStore;
  final MemoryProviderAuditSink auditSink;
  final ProviderAdmissionGate admissionGate;
  final ProviderResiliencePolicy policy;
  final DateTime Function() clock;

  Future<ProviderResponse> execute(ProviderRequest request) async {
    late ProviderDescriptor descriptor;
    try {
      policy.validate();
      descriptor = admissionGate.admit(request, registry);
    } on FormatException catch (error) {
      auditSink.record(
        ProviderAuditEvent(
          requestId: request.requestId,
          providerId: request.providerId,
          operation: request.operation,
          outcome: ProviderAuditOutcome.denied,
          reason: error.message,
        ),
      );
      rethrow;
    }

    final cached = idempotencyStore.read(request.idempotencyKey);
    if (cached != null) {
      if (cached.fingerprint != request.replayFingerprint) {
        auditSink.record(
          ProviderAuditEvent(
            requestId: request.requestId,
            providerId: request.providerId,
            operation: request.operation,
            outcome: ProviderAuditOutcome.denied,
            reason: 'IDEMPOTENCY_KEY_COLLISION',
          ),
        );
        throw const FormatException('IDEMPOTENCY_KEY_COLLISION');
      }
      auditSink.record(
        ProviderAuditEvent(
          requestId: request.requestId,
          providerId: request.providerId,
          operation: request.operation,
          outcome: ProviderAuditOutcome.replayed,
          reason: 'IDEMPOTENT_REPLAY',
        ),
      );
      return cached.response;
    }

    final adapter = registry.require(request.providerId);
    Object? lastError;
    for (var attempt = 1; attempt <= policy.maxAttempts; attempt += 1) {
      try {
        final response = await adapter.execute(request).timeout(policy.timeout);
        response.validateAgainst(request, descriptor);
        idempotencyStore.write(
          request.idempotencyKey,
          ProviderIdempotencyRecord(
            fingerprint: request.replayFingerprint,
            response: response,
          ),
        );
        auditSink.record(
          ProviderAuditEvent(
            requestId: request.requestId,
            providerId: request.providerId,
            operation: request.operation,
            outcome: ProviderAuditOutcome.allowed,
            reason: 'SYNTHETIC_PROVIDER_RESPONSE_ACCEPTED',
          ),
        );
        return response;
      } catch (error) {
        lastError = error;
      }
    }

    if (policy.explicitUnavailableFallback) {
      final response = ProviderResponse.unavailable(
        request: request,
        descriptor: descriptor,
        observedAt: clock(),
      );
      response.validateAgainst(request, descriptor);
      idempotencyStore.write(
        request.idempotencyKey,
        ProviderIdempotencyRecord(
          fingerprint: request.replayFingerprint,
          response: response,
        ),
      );
      auditSink.record(
        ProviderAuditEvent(
          requestId: request.requestId,
          providerId: request.providerId,
          operation: request.operation,
          outcome: ProviderAuditOutcome.failed,
          reason: 'EXPLICIT_UNAVAILABLE_AFTER_${policy.maxAttempts}_ATTEMPTS',
        ),
      );
      return response;
    }

    auditSink.record(
      ProviderAuditEvent(
        requestId: request.requestId,
        providerId: request.providerId,
        operation: request.operation,
        outcome: ProviderAuditOutcome.failed,
        reason: 'PROVIDER_FAILURE_NO_FALLBACK',
      ),
    );
    throw StateError('PROVIDER_FAILURE:$lastError');
  }
}

class SyntheticWebhookEnvelope {
  const SyntheticWebhookEnvelope({
    required this.providerId,
    required this.eventId,
    required this.eventType,
    required this.issuedAt,
    required this.replayKey,
    required this.signature,
    required this.syntheticFixture,
  });

  final String providerId;
  final String eventId;
  final String eventType;
  final DateTime issuedAt;
  final String replayKey;
  final String signature;
  final bool syntheticFixture;
}

class MemoryWebhookReplayStore {
  final Set<String> _keys = {};

  bool contains(String key) => _keys.contains(key);

  void mark(String key) => _keys.add(key);
}

class SyntheticWebhookAdmissionGate {
  SyntheticWebhookAdmissionGate({
    required this.registry,
    required this.replayStore,
  });

  final ProviderAdapterRegistry registry;
  final MemoryWebhookReplayStore replayStore;

  void admit(SyntheticWebhookEnvelope envelope) {
    if (!envelope.syntheticFixture ||
        envelope.signature != phase10SyntheticWebhookSignature ||
        envelope.providerId.trim().isEmpty ||
        envelope.eventId.trim().isEmpty ||
        envelope.eventType.trim().isEmpty ||
        envelope.replayKey.trim().isEmpty ||
        !envelope.issuedAt.isUtc) {
      throw const FormatException('INVALID_SYNTHETIC_WEBHOOK');
    }
    final descriptor = registry.require(envelope.providerId).descriptor;
    descriptor.validate();
    if (replayStore.contains(envelope.replayKey)) {
      throw const FormatException('WEBHOOK_REPLAY_REJECTED');
    }
    replayStore.mark(envelope.replayKey);
  }
}

void _assertNoForbiddenKeys(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString().toLowerCase();
      if (phase10ForbiddenPayloadKeys.contains(key)) {
        throw FormatException('FORBIDDEN_PROVIDER_FIELD:$key');
      }
      _assertNoForbiddenKeys(entry.value);
    }
  } else if (value is Iterable) {
    for (final item in value) {
      _assertNoForbiddenKeys(item);
    }
  }
}
