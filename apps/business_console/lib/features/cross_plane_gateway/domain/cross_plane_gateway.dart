import '../../commercial_mvp/data/commercial_mvp_repository.dart';
import '../../commercial_mvp/domain/commercial_mvp_models.dart';

const phase9CrossPlaneContractVersion = 'manasakna-cross-plane-gateway-v1';
const phase9TravelerProjectionScope = 'journey.read.traveler_projection';
const phase9ConsumerServiceId = 'manasakna-app-phase9';
const phase9BusinessAudience = 'manasakna-business-phase9';
const phase9BusinessSourceProject = 'MANASAKNA_BUSINESS';

const phase9AllowedProjectionFields = <String>{
  'organization',
  'booking',
  'package',
  'traveler_summary',
  'accommodation',
  'flight_summary',
  'freshness',
};

const phase9ForbiddenProjectionFields = <String>{
  'customer_name',
  'full_name',
  'passport_reference',
  'document_reference',
  'finance',
  'payment',
  'payments',
  'margin',
  'commission',
  'supplier_payables',
  'lead',
  'quote',
};

class CrossPlaneServiceIdentity {
  const CrossPlaneServiceIdentity({
    required this.serviceId,
    required this.audience,
    required this.scopes,
  });

  final String serviceId;
  final String audience;
  final Set<String> scopes;

  void validateForBusinessGateway() {
    if (serviceId != phase9ConsumerServiceId) {
      throw const FormatException('UNAUTHORIZED_GATEWAY_SERVICE_ID');
    }
    if (audience != phase9BusinessAudience) {
      throw const FormatException('INVALID_GATEWAY_AUDIENCE');
    }
    if (!scopes.contains(phase9TravelerProjectionScope)) {
      throw const FormatException('MISSING_TRAVELER_PROJECTION_SCOPE');
    }
    if (scopes.any((scope) => scope.toLowerCase().startsWith('hajj.'))) {
      throw const FormatException(
        'HAJJ_SCOPE_PROHIBITED_ON_COMMERCIAL_GATEWAY',
      );
    }
  }

  Map<String, Object?> toJson() => {
    'service_id': serviceId,
    'audience': audience,
    'scopes': scopes.toList()..sort(),
  };

  factory CrossPlaneServiceIdentity.fromJson(Map<String, Object?> json) {
    final rawScopes = json['scopes'];
    if (rawScopes is! List) {
      throw const FormatException('INVALID_GATEWAY_SCOPES');
    }
    return CrossPlaneServiceIdentity(
      serviceId: _requiredString(json, 'service_id'),
      audience: _requiredString(json, 'audience'),
      scopes: rawScopes.whereType<String>().toSet(),
    );
  }
}

class CrossPlaneGatewayRequest {
  const CrossPlaneGatewayRequest({
    required this.contractVersion,
    required this.requestId,
    required this.idempotencyKey,
    required this.requestedAt,
    required this.identity,
    required this.journeyType,
    required this.tenantId,
    required this.bookingId,
    required this.requestedFields,
  });

  final String contractVersion;
  final String requestId;
  final String idempotencyKey;
  final DateTime requestedAt;
  final CrossPlaneServiceIdentity identity;
  final String journeyType;
  final String tenantId;
  final String bookingId;
  final Set<String> requestedFields;

  void validate() {
    if (contractVersion != phase9CrossPlaneContractVersion) {
      throw const FormatException('UNSUPPORTED_CROSS_PLANE_CONTRACT_VERSION');
    }
    if (requestId.trim().isEmpty || idempotencyKey.trim().isEmpty) {
      throw const FormatException('INVALID_GATEWAY_REQUEST_IDENTITY');
    }
    if (!requestedAt.isUtc) {
      throw const FormatException('GATEWAY_REQUEST_TIME_MUST_BE_UTC');
    }
    identity.validateForBusinessGateway();
    if (journeyType != 'umrah') {
      throw const FormatException('COMMERCIAL_GATEWAY_UMRAH_ONLY');
    }
    if (tenantId.trim().isEmpty || bookingId.trim().isEmpty) {
      throw const FormatException('INVALID_GATEWAY_SUBJECT');
    }
    if (requestedFields.isEmpty ||
        requestedFields.difference(phase9AllowedProjectionFields).isNotEmpty) {
      throw const FormatException('UNAUTHORIZED_GATEWAY_FIELD_REQUEST');
    }
  }

  Map<String, Object?> toJson() => {
    'contract_version': contractVersion,
    'request_id': requestId,
    'idempotency_key': idempotencyKey,
    'requested_at': requestedAt.toUtc().toIso8601String(),
    'service_identity': identity.toJson(),
    'journey_type': journeyType,
    'tenant_id': tenantId,
    'booking_id': bookingId,
    'requested_fields': requestedFields.toList()..sort(),
  };

  factory CrossPlaneGatewayRequest.fromJson(Map<String, Object?> json) {
    final requestedAt = DateTime.tryParse(
      _requiredString(json, 'requested_at'),
    );
    final identityRaw = json['service_identity'];
    final requestedFieldsRaw = json['requested_fields'];
    if (requestedAt == null ||
        identityRaw is! Map ||
        requestedFieldsRaw is! List) {
      throw const FormatException('INVALID_GATEWAY_REQUEST_ENVELOPE');
    }
    final request = CrossPlaneGatewayRequest(
      contractVersion: _requiredString(json, 'contract_version'),
      requestId: _requiredString(json, 'request_id'),
      idempotencyKey: _requiredString(json, 'idempotency_key'),
      requestedAt: requestedAt.toUtc(),
      identity: CrossPlaneServiceIdentity.fromJson(
        Map<String, Object?>.from(identityRaw),
      ),
      journeyType: _requiredString(json, 'journey_type'),
      tenantId: _requiredString(json, 'tenant_id'),
      bookingId: _requiredString(json, 'booking_id'),
      requestedFields: requestedFieldsRaw.whereType<String>().toSet(),
    );
    request.validate();
    return request;
  }
}

class CrossPlaneGatewayResponse {
  const CrossPlaneGatewayResponse({
    required this.contractVersion,
    required this.requestId,
    required this.eventId,
    required this.sourceProject,
    required this.sourceAuthority,
    required this.subjectRef,
    required this.observedAt,
    required this.sourceSchemaVersion,
    required this.journeyId,
    required this.journeyType,
    required this.projection,
  });

  final String contractVersion;
  final String requestId;
  final String eventId;
  final String sourceProject;
  final String sourceAuthority;
  final String subjectRef;
  final DateTime observedAt;
  final String sourceSchemaVersion;
  final String journeyId;
  final String journeyType;
  final Map<String, Object?> projection;

  Map<String, Object?> toJson() => {
    'contract_version': contractVersion,
    'request_id': requestId,
    'event_id': eventId,
    'source_project': sourceProject,
    'source_authority': sourceAuthority,
    'subject_ref': subjectRef,
    'observed_at': observedAt.toUtc().toIso8601String(),
    'source_schema_version': sourceSchemaVersion,
    'journey_id': journeyId,
    'journey_type': journeyType,
    'authority_provenance': {
      'source_authority': sourceAuthority,
      'source_id': sourceProject,
      'observed_at': observedAt.toUtc().toIso8601String(),
      'is_authoritative': true,
    },
    'projection': projection,
  };
}

class CrossPlaneIdempotencyRecord {
  const CrossPlaneIdempotencyRecord({
    required this.requestId,
    required this.tenantId,
    required this.bookingId,
    required this.response,
  });

  final String requestId;
  final String tenantId;
  final String bookingId;
  final CrossPlaneGatewayResponse response;

  bool matches(CrossPlaneGatewayRequest request) =>
      requestId == request.requestId &&
      tenantId == request.tenantId &&
      bookingId == request.bookingId;
}

abstract interface class CrossPlaneIdempotencyStore {
  CrossPlaneIdempotencyRecord? read(String idempotencyKey);
  void write(String idempotencyKey, CrossPlaneIdempotencyRecord record);
}

class MemoryCrossPlaneIdempotencyStore implements CrossPlaneIdempotencyStore {
  final Map<String, CrossPlaneIdempotencyRecord> _records = {};

  @override
  CrossPlaneIdempotencyRecord? read(String idempotencyKey) =>
      _records[idempotencyKey];

  @override
  void write(String idempotencyKey, CrossPlaneIdempotencyRecord record) {
    _records[idempotencyKey] = record;
  }
}

enum CrossPlaneAuditOutcome { allowed, replayed, denied, failed }

class CrossPlaneAuditEvent {
  const CrossPlaneAuditEvent({
    required this.requestId,
    required this.subjectRef,
    required this.serviceId,
    required this.outcome,
    required this.reason,
  });

  final String requestId;
  final String subjectRef;
  final String serviceId;
  final CrossPlaneAuditOutcome outcome;
  final String reason;
}

abstract interface class CrossPlaneAuditSink {
  void record(CrossPlaneAuditEvent event);
}

class MemoryCrossPlaneAuditSink implements CrossPlaneAuditSink {
  final List<CrossPlaneAuditEvent> events = [];

  @override
  void record(CrossPlaneAuditEvent event) => events.add(event);
}

class BusinessCrossPlaneGatewayService {
  BusinessCrossPlaneGatewayService({
    required this.repository,
    required this.idempotencyStore,
    required this.auditSink,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  final CommercialMvpRepository repository;
  final CrossPlaneIdempotencyStore idempotencyStore;
  final CrossPlaneAuditSink auditSink;
  final DateTime Function() clock;

  Future<CrossPlaneGatewayResponse> handle(
    CrossPlaneGatewayRequest request,
  ) async {
    try {
      request.validate();

      final cached = idempotencyStore.read(request.idempotencyKey);
      if (cached != null) {
        if (!cached.matches(request)) {
          throw const FormatException('IDEMPOTENCY_KEY_COLLISION');
        }
        auditSink.record(
          CrossPlaneAuditEvent(
            requestId: request.requestId,
            subjectRef: request.bookingId,
            serviceId: request.identity.serviceId,
            outcome: CrossPlaneAuditOutcome.replayed,
            reason: 'IDEMPOTENT_REPLAY',
          ),
        );
        return cached.response;
      }

      final commercial = await repository.journeyContext(
        tenantId: request.tenantId,
        bookingId: request.bookingId,
      );
      if (!commercial.isCommercialUmrah) {
        throw const FormatException('INVALID_COMMERCIAL_UMRAH_SOURCE');
      }

      final response = _buildResponse(request, commercial);
      idempotencyStore.write(
        request.idempotencyKey,
        CrossPlaneIdempotencyRecord(
          requestId: request.requestId,
          tenantId: request.tenantId,
          bookingId: request.bookingId,
          response: response,
        ),
      );
      auditSink.record(
        CrossPlaneAuditEvent(
          requestId: request.requestId,
          subjectRef: request.bookingId,
          serviceId: request.identity.serviceId,
          outcome: CrossPlaneAuditOutcome.allowed,
          reason: 'TRAVELER_SAFE_PROJECTION_ISSUED',
        ),
      );
      return response;
    } on FormatException catch (error) {
      auditSink.record(
        CrossPlaneAuditEvent(
          requestId: request.requestId,
          subjectRef: request.bookingId,
          serviceId: request.identity.serviceId,
          outcome: CrossPlaneAuditOutcome.denied,
          reason: error.message,
        ),
      );
      rethrow;
    } catch (_) {
      auditSink.record(
        CrossPlaneAuditEvent(
          requestId: request.requestId,
          subjectRef: request.bookingId,
          serviceId: request.identity.serviceId,
          outcome: CrossPlaneAuditOutcome.failed,
          reason: 'GATEWAY_SOURCE_FAILURE',
        ),
      );
      rethrow;
    }
  }

  CrossPlaneGatewayResponse _buildResponse(
    CrossPlaneGatewayRequest request,
    CommercialJourneyContext commercial,
  ) {
    final projection = <String, Object?>{};

    if (request.requestedFields.contains('organization')) {
      projection['organization'] = {'tenant_name': commercial.tenantName};
    }
    if (request.requestedFields.contains('booking')) {
      projection['booking'] = {'booking_code': commercial.bookingCode};
    }
    if (request.requestedFields.contains('package')) {
      projection['package'] = {'name': commercial.packageName};
    }
    if (request.requestedFields.contains('traveler_summary')) {
      projection['traveler_summary'] = {'count': commercial.travelerCount};
    }
    if (request.requestedFields.contains('accommodation')) {
      projection['accommodation'] = {'room_label': commercial.roomLabel};
    }
    if (request.requestedFields.contains('flight_summary')) {
      projection['flight_summary'] = {'count': commercial.flightCount};
    }
    if (request.requestedFields.contains('freshness')) {
      projection['freshness'] = commercial.freshness;
    }

    _assertProjectionIsMinimized(projection);
    final observedAt = clock().toUtc();

    return CrossPlaneGatewayResponse(
      contractVersion: phase9CrossPlaneContractVersion,
      requestId: request.requestId,
      eventId: 'business-gateway:${request.requestId}',
      sourceProject: phase9BusinessSourceProject,
      sourceAuthority: 'commercialCompany',
      subjectRef: request.bookingId,
      observedAt: observedAt,
      sourceSchemaVersion: commercial.schemaVersion,
      journeyId: commercial.journeyId,
      journeyType: commercial.journeyType,
      projection: Map.unmodifiable(projection),
    );
  }
}

void _assertProjectionIsMinimized(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString();
      if (phase9ForbiddenProjectionFields.contains(key)) {
        throw FormatException('FORBIDDEN_GATEWAY_FIELD:$key');
      }
      _assertProjectionIsMinimized(entry.value);
    }
  } else if (value is Iterable) {
    for (final item in value) {
      _assertProjectionIsMinimized(item);
    }
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('INVALID_GATEWAY_FIELD:$key');
  }
  return value;
}
