import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/commercial_mvp/data/commercial_mvp_repository.dart';
import 'package:manasakna_business_console/features/commercial_mvp/domain/commercial_mvp_models.dart';
import 'package:manasakna_business_console/features/cross_plane_gateway/domain/cross_plane_gateway.dart';

class _FakeCommercialMvpRepository implements CommercialMvpRepository {
  int journeyCalls = 0;

  @override
  Future<CommercialJourneyContext> journeyContext({
    required String tenantId,
    required String bookingId,
  }) async {
    journeyCalls += 1;
    return const CommercialJourneyContext(
      schemaVersion: 'commercial-umrah-journey-context-v1',
      journeyId: 'booking-1',
      journeyType: 'umrah',
      sourceAuthority: 'commercialCompany',
      tenantName: 'شركة تجريبية',
      bookingCode: 'B-001',
      packageName: 'عمرة تجريبية',
      travelerCount: 2,
      flightCount: 1,
      roomLabel: 'SYN-101',
      freshness: 'fresh',
    );
  }

  @override
  Future<List<CommercialBookingSummary>> listBookings(String tenantId) async =>
      const [];

  @override
  Future<PipelineSummary> pipelineSummary(String tenantId) async =>
      PipelineSummary.empty();
}

CrossPlaneGatewayRequest request({
  String requestId = 'req-001',
  String idempotencyKey = 'idem-001',
  String journeyType = 'umrah',
  Set<String>? scopes,
  Set<String>? requestedFields,
  String bookingId = 'booking-1',
}) {
  return CrossPlaneGatewayRequest(
    contractVersion: phase9CrossPlaneContractVersion,
    requestId: requestId,
    idempotencyKey: idempotencyKey,
    requestedAt: DateTime.utc(2026, 9, 23, 20),
    identity: CrossPlaneServiceIdentity(
      serviceId: phase9ConsumerServiceId,
      audience: phase9BusinessAudience,
      scopes: scopes ?? {phase9TravelerProjectionScope},
    ),
    journeyType: journeyType,
    tenantId: 'tenant-1',
    bookingId: bookingId,
    requestedFields: requestedFields ?? phase9AllowedProjectionFields,
  );
}

BusinessCrossPlaneGatewayService _service(
  _FakeCommercialMvpRepository repository,
  MemoryCrossPlaneIdempotencyStore idempotency,
  MemoryCrossPlaneAuditSink audit,
) {
  return BusinessCrossPlaneGatewayService(
    repository: repository,
    idempotencyStore: idempotency,
    auditSink: audit,
    clock: () => DateTime.utc(2026, 9, 23, 20, 15),
  );
}

void main() {
  test('Phase 9 contract manifest is non-production and DB-isolated', () {
    final raw = File(
      '../../docs/MANASAKNA_CROSS_PLANE_GATEWAY_CONTRACT_V1.json',
    ).readAsStringSync();
    final manifest = jsonDecode(raw) as Map<String, dynamic>;

    expect(manifest['contract_version'], phase9CrossPlaneContractVersion);
    expect(manifest['direct_cross_plane_db_access'], isFalse);
    expect(manifest['synthetic_non_production_default'], isTrue);
    expect(
      Set<String>.from(manifest['allowed_projection_fields'] as List),
      phase9AllowedProjectionFields,
    );
  });

  test(
    'issues only minimized traveler-safe commercial Umrah projection',
    () async {
      final repository = _FakeCommercialMvpRepository();
      final idempotency = MemoryCrossPlaneIdempotencyStore();
      final audit = MemoryCrossPlaneAuditSink();

      final response = await _service(
        repository,
        idempotency,
        audit,
      ).handle(request());
      final json = response.toJson();
      final encoded = jsonEncode(json);

      expect(response.contractVersion, phase9CrossPlaneContractVersion);
      expect(response.sourceProject, phase9BusinessSourceProject);
      expect(response.sourceAuthority, 'commercialCompany');
      expect(response.journeyType, 'umrah');
      expect(response.projection.keys.toSet(), phase9AllowedProjectionFields);
      expect(encoded, isNot(contains('passport_reference')));
      expect(encoded, isNot(contains('finance')));
      expect(encoded, isNot(contains('payment')));
      expect(encoded, isNot(contains('margin')));
      expect(encoded, isNot(contains('commission')));
      expect(encoded, isNot(contains('supplier_payables')));
      expect(repository.journeyCalls, 1);
      expect(audit.events.single.outcome, CrossPlaneAuditOutcome.allowed);
    },
  );

  test(
    'idempotent replay returns cached response without source reread',
    () async {
      final repository = _FakeCommercialMvpRepository();
      final idempotency = MemoryCrossPlaneIdempotencyStore();
      final audit = MemoryCrossPlaneAuditSink();
      final gateway = _service(repository, idempotency, audit);

      final first = await gateway.handle(request());
      final second = await gateway.handle(request());

      expect(identical(first, second), isTrue);
      expect(repository.journeyCalls, 1);
      expect(audit.events.last.outcome, CrossPlaneAuditOutcome.replayed);
    },
  );

  test('idempotency key collision fails closed', () async {
    final repository = _FakeCommercialMvpRepository();
    final gateway = _service(
      repository,
      MemoryCrossPlaneIdempotencyStore(),
      MemoryCrossPlaneAuditSink(),
    );

    await gateway.handle(request());
    await expectLater(
      gateway.handle(request(requestId: 'req-002', bookingId: 'booking-2')),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'IDEMPOTENCY_KEY_COLLISION',
        ),
      ),
    );
    expect(repository.journeyCalls, 1);
  });

  test(
    'Hajj requests are rejected before commercial repository access',
    () async {
      final repository = _FakeCommercialMvpRepository();
      final audit = MemoryCrossPlaneAuditSink();

      await expectLater(
        _service(
          repository,
          MemoryCrossPlaneIdempotencyStore(),
          audit,
        ).handle(request(journeyType: 'hajj')),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            'COMMERCIAL_GATEWAY_UMRAH_ONLY',
          ),
        ),
      );

      expect(repository.journeyCalls, 0);
      expect(audit.events.single.outcome, CrossPlaneAuditOutcome.denied);
    },
  );

  test('missing traveler projection scope fails closed', () async {
    final repository = _FakeCommercialMvpRepository();

    await expectLater(
      _service(
        repository,
        MemoryCrossPlaneIdempotencyStore(),
        MemoryCrossPlaneAuditSink(),
      ).handle(request(scopes: const {'booking.read'})),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'MISSING_TRAVELER_PROJECTION_SCOPE',
        ),
      ),
    );

    expect(repository.journeyCalls, 0);
  });

  test('Hajj scope cannot ride on commercial service identity', () async {
    final repository = _FakeCommercialMvpRepository();

    await expectLater(
      _service(
        repository,
        MemoryCrossPlaneIdempotencyStore(),
        MemoryCrossPlaneAuditSink(),
      ).handle(
        request(
          scopes: const {
            phase9TravelerProjectionScope,
            'hajj.eligibility.manage',
          },
        ),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'HAJJ_SCOPE_PROHIBITED_ON_COMMERCIAL_GATEWAY',
        ),
      ),
    );

    expect(repository.journeyCalls, 0);
  });

  test('unapproved requested field is rejected', () async {
    final repository = _FakeCommercialMvpRepository();

    await expectLater(
      _service(
        repository,
        MemoryCrossPlaneIdempotencyStore(),
        MemoryCrossPlaneAuditSink(),
      ).handle(request(requestedFields: const {'organization', 'finance'})),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          'UNAUTHORIZED_GATEWAY_FIELD_REQUEST',
        ),
      ),
    );

    expect(repository.journeyCalls, 0);
  });

  test('request JSON round trip preserves exact contract boundary', () {
    final original = request();
    final parsed = CrossPlaneGatewayRequest.fromJson(original.toJson());

    expect(parsed.contractVersion, phase9CrossPlaneContractVersion);
    expect(parsed.identity.serviceId, phase9ConsumerServiceId);
    expect(parsed.identity.audience, phase9BusinessAudience);
    expect(parsed.requestedFields, phase9AllowedProjectionFields);
    expect(parsed.requestedAt.isUtc, isTrue);
  });
}
