import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/official_external_integrations/domain/official_external_integrations.dart';

ProviderRequest request({
  String providerId = 'official-regulatory-synthetic-v1',
  String operation = 'official.status.read',
  String requestId = 'req-001',
  String idempotencyKey = 'idem-001',
  bool syntheticFixture = true,
  Map<String, Object?> payload = const {},
}) =>
    ProviderRequest(
      contractVersion: phase10IntegrationContractVersion,
      requestId: requestId,
      idempotencyKey: idempotencyKey,
      requestedAt: DateTime.utc(2026, 9, 29, 20),
      providerId: providerId,
      operation: operation,
      subjectRef: 'subject-synthetic-1',
      dataClassification: 'synthetic_test',
      syntheticFixture: syntheticFixture,
      payload: payload,
    );

ProviderIntegrationClient client(
  ProviderAdapterRegistry registry, {
  ProviderResiliencePolicy policy = const ProviderResiliencePolicy(),
}) =>
    ProviderIntegrationClient(
      registry: registry,
      idempotencyStore: MemoryProviderIdempotencyStore(),
      auditSink: MemoryProviderAuditSink(),
      policy: policy,
      clock: () => DateTime.utc(2026, 9, 29, 20, 30),
    );

final class _FailingAdapter implements ProviderAdapter {
  int calls = 0;

  @override
  ProviderDescriptor get descriptor => const ProviderDescriptor(
        providerId: 'failing-synthetic-v1',
        providerClass: ExternalProviderClass.travel,
        authority: ProviderAuthority.commercialProvider,
        sourceOfTruthDomain: 'synthetic_failure',
        allowedOperations: {'travel.availability.preview'},
      );

  @override
  Future<ProviderResponse> execute(ProviderRequest request) async {
    calls += 1;
    throw StateError('synthetic failure');
  }
}

void main() {
  test('Phase 10 manifest is synthetic and real-provider closed', () {
    final manifest = jsonDecode(
      File('../../docs/MANASAKNA_PHASE_10_PROVIDER_INTEGRATION_CONTRACT_V1.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(manifest['contract_version'], phase10IntegrationContractVersion);
    expect(manifest['execution_mode'], phase10ExecutionMode);
    expect(manifest['real_provider_activation_authorized'], isFalse);
    expect(manifest['direct_cross_plane_db_access'], isFalse);
    expect(manifest['shared_database_mutation'], isFalse);
    expect(manifest['production'], isFalse);
    expect(manifest['real_data'], isFalse);
  });

  test('catalog exposes exactly four non-production provider classes', () {
    final registry = ProviderAdapterRegistry.synthetic();
    final descriptors = registry.descriptors;

    expect(descriptors, hasLength(4));
    expect(descriptors.map((d) => d.providerClass).toSet(), {
      ExternalProviderClass.officialRegulatory,
      ExternalProviderClass.messaging,
      ExternalProviderClass.payment,
      ExternalProviderClass.travel,
    });
    expect(descriptors.every((d) => !d.realActivationAuthorized), isTrue);
  });

  test('official synthetic read preserves government provenance without claim', () async {
    final registry = ProviderAdapterRegistry.synthetic(
      clock: () => DateTime.utc(2026, 9, 29, 20, 15),
    );
    final response = await client(registry).execute(request());

    expect(response.availability, ProviderAvailability.available);
    expect(response.payload['status'], 'synthetic_only');
    expect(response.payload['source_note'], 'not_an_official_record');
    expect(response.provenance.authority, ProviderAuthority.government);
    expect(response.provenance.synthetic, isTrue);
    expect(response.provenance.authoritativeSourceClaim, isFalse);
  });

  test('Hajj sovereign mutation is rejected fail closed', () async {
    final registry = ProviderAdapterRegistry.synthetic();

    await expectLater(
      client(registry).execute(request(operation: 'hajj.status.write')),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          anyOf(
            'PROVIDER_OPERATION_NOT_ALLOWED',
            'HAJJ_SOVEREIGN_MUTATION_PROHIBITED',
          ),
        ),
      ),
    );
  });

  test('unmarked real provider data is rejected before adapter execution', () async {
    final registry = ProviderAdapterRegistry.synthetic();
    final adapter = registry.require('official-regulatory-synthetic-v1')
        as SyntheticOfficialRegulatoryAdapter;

    await expectLater(
      client(registry).execute(request(syntheticFixture: false)),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'REAL_OR_UNMARKED_PROVIDER_DATA_PROHIBITED',
        ),
      ),
    );
    expect(adapter.callCount, 0);
  });

  test('nested credential material is prohibited', () async {
    final registry = ProviderAdapterRegistry.synthetic();

    await expectLater(
      client(registry).execute(
        request(payload: const {
          'safe': {'client_secret': 'must-never-enter-phase10'},
        }),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'FORBIDDEN_PROVIDER_FIELD:client_secret',
        ),
      ),
    );
  });

  test('unknown provider fails closed', () async {
    final registry = ProviderAdapterRegistry.synthetic();

    await expectLater(
      client(registry).execute(request(providerId: 'unknown-provider')),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'UNKNOWN_PROVIDER',
        ),
      ),
    );
  });

  test('idempotent replay does not call adapter twice', () async {
    final registry = ProviderAdapterRegistry.synthetic();
    final adapter = registry.require('messaging-synthetic-v1')
        as SyntheticMessagingAdapter;
    final store = MemoryProviderIdempotencyStore();
    final audit = MemoryProviderAuditSink();
    final gateway = ProviderIntegrationClient(
      registry: registry,
      idempotencyStore: store,
      auditSink: audit,
    );
    final messageRequest = request(
      providerId: 'messaging-synthetic-v1',
      operation: 'message.preview',
    );

    final first = await gateway.execute(messageRequest);
    final second = await gateway.execute(messageRequest);

    expect(identical(first, second), isTrue);
    expect(adapter.callCount, 1);
    expect(audit.events.last.outcome, ProviderAuditOutcome.replayed);
  });

  test('idempotency collision is rejected', () async {
    final registry = ProviderAdapterRegistry.synthetic();
    final store = MemoryProviderIdempotencyStore();
    final gateway = ProviderIntegrationClient(
      registry: registry,
      idempotencyStore: store,
      auditSink: MemoryProviderAuditSink(),
    );

    await gateway.execute(request());
    await expectLater(
      gateway.execute(request(requestId: 'req-002')),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'IDEMPOTENCY_KEY_COLLISION',
        ),
      ),
    );
  });

  test('payment adapter is preview-only and cannot charge', () async {
    final registry = ProviderAdapterRegistry.synthetic();
    final response = await client(registry).execute(
      request(
        providerId: 'payment-synthetic-v1',
        operation: 'payment.intent.preview',
        payload: const {'amount_minor': 12500, 'currency': 'USD'},
      ),
    );

    expect(response.payload['status'], 'synthetic_no_charge');
    expect(response.payload['amount_minor'], 12500);
    expect(response.payload['reference'], startsWith('PAY-SYN-'));
  });

  test('messaging adapter never claims delivery', () async {
    final registry = ProviderAdapterRegistry.synthetic();
    final response = await client(registry).execute(
      request(
        providerId: 'messaging-synthetic-v1',
        operation: 'message.preview',
      ),
    );

    expect(response.payload['delivery_state'], 'preview_not_delivered');
  });

  test('travel adapter never calls live inventory', () async {
    final registry = ProviderAdapterRegistry.synthetic();
    final response = await client(registry).execute(
      request(
        providerId: 'travel-synthetic-v1',
        operation: 'travel.availability.preview',
      ),
    );

    expect(response.payload['status'], 'synthetic_availability');
    expect(response.payload['source_note'], 'no_live_inventory_call');
  });

  test('bounded provider failure becomes explicit unavailable state', () async {
    final failing = _FailingAdapter();
    final registry = ProviderAdapterRegistry([failing]);
    final audit = MemoryProviderAuditSink();
    final gateway = ProviderIntegrationClient(
      registry: registry,
      idempotencyStore: MemoryProviderIdempotencyStore(),
      auditSink: audit,
      policy: const ProviderResiliencePolicy(
        timeout: Duration(milliseconds: 50),
        maxAttempts: 2,
        explicitUnavailableFallback: true,
      ),
      clock: () => DateTime.utc(2026, 9, 29, 20, 30),
    );

    final response = await gateway.execute(
      request(
        providerId: 'failing-synthetic-v1',
        operation: 'travel.availability.preview',
      ),
    );

    expect(failing.calls, 2);
    expect(response.availability, ProviderAvailability.unavailable);
    expect(response.payload['status'], 'unavailable');
    expect(audit.events.last.outcome, ProviderAuditOutcome.failed);
  });

  test('synthetic webhook gate verifies fixture and rejects replay', () {
    final registry = ProviderAdapterRegistry.synthetic();
    final replay = MemoryWebhookReplayStore();
    final gate = SyntheticWebhookAdmissionGate(
      registry: registry,
      replayStore: replay,
    );
    final envelope = SyntheticWebhookEnvelope(
      providerId: 'payment-synthetic-v1',
      eventId: 'evt-001',
      eventType: 'payment.status.synthetic',
      issuedAt: DateTime.utc(2026, 9, 29, 20),
      replayKey: 'replay-001',
      signature: phase10SyntheticWebhookSignature,
      syntheticFixture: true,
    );

    gate.admit(envelope);
    expect(
      () => gate.admit(envelope),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'WEBHOOK_REPLAY_REJECTED',
        ),
      ),
    );
  });

  test('synthetic webhook rejects invalid signature', () {
    final gate = SyntheticWebhookAdmissionGate(
      registry: ProviderAdapterRegistry.synthetic(),
      replayStore: MemoryWebhookReplayStore(),
    );

    expect(
      () => gate.admit(
        SyntheticWebhookEnvelope(
          providerId: 'messaging-synthetic-v1',
          eventId: 'evt-002',
          eventType: 'message.status.synthetic',
          issuedAt: DateTime.utc(2026, 9, 29, 20),
          replayKey: 'replay-002',
          signature: 'not-valid',
          syntheticFixture: true,
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'INVALID_SYNTHETIC_WEBHOOK',
        ),
      ),
    );
  });
}
