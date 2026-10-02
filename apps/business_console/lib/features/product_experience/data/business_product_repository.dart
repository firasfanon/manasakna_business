import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class BusinessProductRepository {
  Future<Map<String, dynamic>> dashboard(String tenantId);
  Future<List<Map<String, dynamic>>> list(
    String tenantId,
    String resource, {
    int limit = 100,
  });
  Future<Map<String, dynamic>> saveCustomer(
    String tenantId, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> saveLead(
    String tenantId,
    String customerId, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> saveQuote(
    String tenantId,
    String leadId, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> saveQuoteItem(
    String tenantId,
    String quoteId, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> saveBooking(
    String tenantId,
    String quoteId, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> saveTraveler(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> saveTask(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> saveSupport(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> saveFinance(
    String tenantId,
    String bookingId,
    Map<String, dynamic> payload,
  );
  Future<Map<String, dynamic>> updateStatus(
    String tenantId,
    String resource,
    String id,
    String status, {
    String? reason,
  });
  Future<Map<String, dynamic>> advanceBooking(
    String tenantId,
    String bookingId,
    String stage, {
    String? reason,
    String? idempotencyKey,
  });
  Future<Map<String, dynamic>> bookingReadiness(
    String tenantId,
    String bookingId,
  );
}

class SupabaseBusinessProductRepository implements BusinessProductRepository {
  SupabaseBusinessProductRepository(this._client);
  final SupabaseClient _client;

  Map<String, dynamic> _map(dynamic value, String error) {
    if (value is! Map) throw FormatException(error);
    return value.map((k, v) => MapEntry(k.toString(), v));
  }

  @override
  Future<Map<String, dynamic>> dashboard(String tenantId) async => _map(
    await _client.rpc(
      'rpc_business_phase13_dashboard_v1',
      params: {'p_tenant_id': tenantId},
    ),
    'INVALID_PHASE13_DASHBOARD',
  );

  @override
  Future<List<Map<String, dynamic>>> list(
    String tenantId,
    String resource, {
    int limit = 100,
  }) async {
    final response = await _client.rpc(
      'rpc_business_phase13_list_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_resource': resource,
        'p_limit': limit,
      },
    );
    if (response is! List) throw const FormatException('INVALID_PHASE13_LIST');
    return response
        .whereType<Map>()
        .map((x) => x.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> saveCustomer(
    String tenantId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_customer_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_customer_id': id,
        'p_payload': payload,
      },
    ),
    'INVALID_CUSTOMER_SAVE',
  );

  @override
  Future<Map<String, dynamic>> saveLead(
    String tenantId,
    String customerId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_lead_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_lead_id': id,
        'p_customer_id': customerId,
        'p_payload': payload,
      },
    ),
    'INVALID_LEAD_SAVE',
  );

  @override
  Future<Map<String, dynamic>> saveQuote(
    String tenantId,
    String leadId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_quote_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_quote_id': id,
        'p_lead_id': leadId,
        'p_payload': payload,
      },
    ),
    'INVALID_QUOTE_SAVE',
  );

  @override
  Future<Map<String, dynamic>> saveQuoteItem(
    String tenantId,
    String quoteId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_quote_item_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_item_id': id,
        'p_quote_id': quoteId,
        'p_payload': payload,
      },
    ),
    'INVALID_QUOTE_ITEM_SAVE',
  );

  @override
  Future<Map<String, dynamic>> saveBooking(
    String tenantId,
    String quoteId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_booking_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_booking_id': id,
        'p_quote_id': quoteId,
        'p_payload': payload,
      },
    ),
    'INVALID_BOOKING_SAVE',
  );

  @override
  Future<Map<String, dynamic>> saveTraveler(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_traveler_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_booking_id': bookingId,
        'p_traveler_id': id,
        'p_payload': payload,
      },
    ),
    'INVALID_TRAVELER_SAVE',
  );

  @override
  Future<Map<String, dynamic>> saveTask(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_task_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_task_id': id,
        'p_booking_id': bookingId,
        'p_payload': payload,
      },
    ),
    'INVALID_TASK_SAVE',
  );

  @override
  Future<Map<String, dynamic>> saveSupport(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_support_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_case_id': id,
        'p_booking_id': bookingId,
        'p_payload': payload,
      },
    ),
    'INVALID_SUPPORT_SAVE',
  );

  @override
  Future<Map<String, dynamic>> saveFinance(
    String tenantId,
    String bookingId,
    Map<String, dynamic> payload,
  ) async => _map(
    await _client.rpc(
      'rpc_business_phase13_save_finance_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_booking_id': bookingId,
        'p_payload': payload,
      },
    ),
    'INVALID_FINANCE_SAVE',
  );

  @override
  Future<Map<String, dynamic>> updateStatus(
    String tenantId,
    String resource,
    String id,
    String status, {
    String? reason,
  }) async => _map(
    await _client.rpc(
      'rpc_business_phase13_update_status_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_resource': resource,
        'p_id': id,
        'p_status': status,
        'p_reason': reason,
      },
    ),
    'INVALID_STATUS_UPDATE',
  );

  @override
  Future<Map<String, dynamic>> advanceBooking(
    String tenantId,
    String bookingId,
    String stage, {
    String? reason,
    String? idempotencyKey,
  }) async => _map(
    await _client.rpc(
      'rpc_business_advance_booking_stage_v1',
      params: {
        'p_tenant_id': tenantId,
        'p_booking_id': bookingId,
        'p_to_stage': stage,
        'p_reason': reason,
        'p_idempotency_key': idempotencyKey,
      },
    ),
    'INVALID_BOOKING_STAGE_UPDATE',
  );

  @override
  Future<Map<String, dynamic>> bookingReadiness(
    String tenantId,
    String bookingId,
  ) async => _map(
    await _client.rpc(
      'rpc_business_booking_readiness_v1',
      params: {'p_tenant_id': tenantId, 'p_booking_id': bookingId},
    ),
    'INVALID_BOOKING_READINESS',
  );
}
