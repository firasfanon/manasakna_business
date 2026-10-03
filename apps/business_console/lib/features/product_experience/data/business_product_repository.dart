import 'package:supabase_flutter/supabase_flutter.dart';

/// Bounded data contract for the business product. Implementations must enforce
/// tenant scope in the backing store; the UI never addresses tables directly.
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

  /// Bounded CRUD for operational resources that do not have a dedicated
  /// workflow method yet. The resource name is allow-listed server side.
  Future<Map<String, dynamic>> saveResource(
    String tenantId,
    String resource, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> submitPublicLead(
    String tenantId,
    Map<String, dynamic> payload,
  );
  Future<List<Map<String, dynamic>>> adminList(
    String tenantId,
    String resource,
  );
  Future<Map<String, dynamic>> adminSave(
    String tenantId,
    String resource, {
    String? id,
    required Map<String, dynamic> payload,
  });
  Future<Map<String, dynamic>> entity360(
    String tenantId,
    String entity,
    String id,
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

  Future<Map<String, dynamic>> _save(
    String rpc,
    Map<String, dynamic> params,
    String error,
  ) async => _map(await _client.rpc(rpc, params: params), error);

  @override
  Future<Map<String, dynamic>> saveCustomer(
    String tenantId, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_customer_v1', {
    'p_tenant_id': tenantId,
    'p_customer_id': id,
    'p_payload': payload,
  }, 'INVALID_CUSTOMER_SAVE');
  @override
  Future<Map<String, dynamic>> saveLead(
    String tenantId,
    String customerId, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_lead_v1', {
    'p_tenant_id': tenantId,
    'p_lead_id': id,
    'p_customer_id': customerId,
    'p_payload': payload,
  }, 'INVALID_LEAD_SAVE');
  @override
  Future<Map<String, dynamic>> saveQuote(
    String tenantId,
    String leadId, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_quote_v1', {
    'p_tenant_id': tenantId,
    'p_quote_id': id,
    'p_lead_id': leadId,
    'p_payload': payload,
  }, 'INVALID_QUOTE_SAVE');
  @override
  Future<Map<String, dynamic>> saveQuoteItem(
    String tenantId,
    String quoteId, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_quote_item_v1', {
    'p_tenant_id': tenantId,
    'p_item_id': id,
    'p_quote_id': quoteId,
    'p_payload': payload,
  }, 'INVALID_QUOTE_ITEM_SAVE');
  @override
  Future<Map<String, dynamic>> saveBooking(
    String tenantId,
    String quoteId, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_booking_v1', {
    'p_tenant_id': tenantId,
    'p_booking_id': id,
    'p_quote_id': quoteId,
    'p_payload': payload,
  }, 'INVALID_BOOKING_SAVE');
  @override
  Future<Map<String, dynamic>> saveTraveler(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_traveler_v1', {
    'p_tenant_id': tenantId,
    'p_booking_id': bookingId,
    'p_traveler_id': id,
    'p_payload': payload,
  }, 'INVALID_TRAVELER_SAVE');
  @override
  Future<Map<String, dynamic>> saveTask(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_task_v1', {
    'p_tenant_id': tenantId,
    'p_task_id': id,
    'p_booking_id': bookingId,
    'p_payload': payload,
  }, 'INVALID_TASK_SAVE');
  @override
  Future<Map<String, dynamic>> saveSupport(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_support_v1', {
    'p_tenant_id': tenantId,
    'p_case_id': id,
    'p_booking_id': bookingId,
    'p_payload': payload,
  }, 'INVALID_SUPPORT_SAVE');
  @override
  Future<Map<String, dynamic>> saveFinance(
    String tenantId,
    String bookingId,
    Map<String, dynamic> payload,
  ) => _save('rpc_business_phase13_save_finance_v1', {
    'p_tenant_id': tenantId,
    'p_booking_id': bookingId,
    'p_payload': payload,
  }, 'INVALID_FINANCE_SAVE');

  @override
  Future<Map<String, dynamic>> updateStatus(
    String tenantId,
    String resource,
    String id,
    String status, {
    String? reason,
  }) => _save('rpc_business_phase13_update_status_v1', {
    'p_tenant_id': tenantId,
    'p_resource': (resource == 'packages'
        ? 'package'
        : resource == 'departures'
        ? 'departure'
        : resource),
    'p_id': id,
    'p_status': status,
    'p_reason': reason,
  }, 'INVALID_STATUS_UPDATE');
  @override
  Future<Map<String, dynamic>> advanceBooking(
    String tenantId,
    String bookingId,
    String stage, {
    String? reason,
    String? idempotencyKey,
  }) => _save('rpc_business_advance_booking_stage_v1', {
    'p_tenant_id': tenantId,
    'p_booking_id': bookingId,
    'p_to_stage': stage,
    'p_reason': reason,
    'p_idempotency_key': idempotencyKey,
  }, 'INVALID_BOOKING_STAGE_UPDATE');
  @override
  Future<Map<String, dynamic>> bookingReadiness(
    String tenantId,
    String bookingId,
  ) => _save('rpc_business_booking_readiness_v1', {
    'p_tenant_id': tenantId,
    'p_booking_id': bookingId,
  }, 'INVALID_BOOKING_READINESS');
  @override
  Future<Map<String, dynamic>> saveResource(
    String tenantId,
    String resource, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_phase13_save_resource_v1', {
    'p_tenant_id': tenantId,
    'p_resource': (resource == 'packages'
        ? 'package'
        : resource == 'departures'
        ? 'departure'
        : resource),
    'p_id': id,
    'p_payload': payload,
  }, 'INVALID_RESOURCE_SAVE');
  @override
  Future<Map<String, dynamic>> submitPublicLead(
    String tenantId,
    Map<String, dynamic> payload,
  ) => _save('rpc_business_public_lead_capture_v1', {
    'p_tenant_id': tenantId,
    'p_payload': payload,
  }, 'INVALID_PUBLIC_LEAD');

  @override
  Future<List<Map<String, dynamic>>> adminList(
    String tenantId,
    String resource,
  ) async {
    final response = await _client.rpc(
      'rpc_business_product_admin_list_v1',
      params: {'p_tenant_id': tenantId, 'p_resource': resource},
    );
    if (response is! List) {
      throw const FormatException('INVALID_ADMIN_LIST');
    }
    return response
        .whereType<Map>()
        .map((x) => x.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> adminSave(
    String tenantId,
    String resource, {
    String? id,
    required Map<String, dynamic> payload,
  }) => _save('rpc_business_product_admin_save_v1', {
    'p_tenant_id': tenantId,
    'p_resource': resource,
    'p_id': id,
    'p_payload': payload,
  }, 'INVALID_ADMIN_SAVE');

  @override
  Future<Map<String, dynamic>> entity360(
    String tenantId,
    String entity,
    String id,
  ) => _save('rpc_business_product_360_v1', {
    'p_tenant_id': tenantId,
    'p_entity': entity,
    'p_id': id,
  }, 'INVALID_ENTITY_360');
}

/// Explicitly synthetic, deterministic store used by preview/UAT. Every form
/// calls this store and the next list/dashboard read observes the mutation.
class InMemoryBusinessProductRepository implements BusinessProductRepository {
  InMemoryBusinessProductRepository({this._tenantId = 'synthetic-tenant'}) {
    _seed();
  }
  final String _tenantId;
  final Map<String, List<Map<String, dynamic>>> _data = {};
  int _sequence = 100;

  void _seed() {
    _data['customers'] = [
      {
        'id': 'customer-001',
        'tenant_id': _tenantId,
        'full_name': 'محمد أحمد الخطيب',
        'phone': '0599001122',
        'status': 'active',
        'data_classification': 'synthetic',
      },
      {
        'id': 'customer-002',
        'tenant_id': _tenantId,
        'full_name': 'سارة محمود',
        'phone': '0568112233',
        'status': 'active',
        'data_classification': 'synthetic',
      },
    ];
    _data['leads'] = [
      {
        'id': 'lead-001',
        'tenant_id': _tenantId,
        'customer_id': 'customer-001',
        'source': 'website',
        'status': 'new',
        'notes': 'طلب برنامج اقتصادي لعائلة',
        'data_classification': 'synthetic',
      },
    ];
    _data['packages'] = [
      {
        'id': 'package-001',
        'tenant_id': _tenantId,
        'name': 'عمرة اقتصادية — 8 أيام',
        'duration_days': 8,
        'base_price': 4850,
        'cost_amount': 3400,
        'margin_amount': 1450,
        'status': 'active',
      },
    ];
    _data['departures'] = [
      {
        'id': 'departure-001',
        'tenant_id': _tenantId,
        'package_id': 'package-001',
        'name': 'مغادرة 15 تشرين الأول',
        'capacity': 24,
        'booked': 18,
        'status': 'open',
      },
    ];
    _data['quotes'] = [
      {
        'id': 'quote-001',
        'tenant_id': _tenantId,
        'lead_id': 'lead-001',
        'customer_id': 'customer-001',
        'title': 'عرض عمرة لعائلة',
        'total_amount': 9700,
        'status': 'draft',
      },
    ];
    _data['bookings'] = [
      {
        'id': 'booking-001',
        'tenant_id': _tenantId,
        'quote_id': 'quote-001',
        'customer_id': 'customer-001',
        'departure_id': 'departure-001',
        'code': 'UMR-SYN-001',
        'workflow_stage': 'booking',
        'total_amount': 9700,
        'paid_amount': 5000,
        'status': 'confirmed',
      },
    ];
    _data['travelers'] = [
      {
        'id': 'traveler-001',
        'tenant_id': _tenantId,
        'booking_id': 'booking-001',
        'full_name': 'عمر أبو عمر',
        'passport_reference': 'synthetic-passport-001',
        'readiness': 'ready',
      },
    ];
    _data['organizations'] = [
      {
        'id': 'organization-001',
        'tenant_id': _tenantId,
        'name': 'شركة العمرة التجريبية',
        'legal_name': 'شركة العمرة التجريبية',
      },
    ];
    _data['branches'] = [
      {
        'id': 'branch-001',
        'tenant_id': _tenantId,
        'organization_id': 'organization-001',
        'code': 'HQ',
        'name': 'الفرع الرئيسي',
        'timezone': 'Asia/Hebron',
        'is_active': true,
      },
    ];
    _data['staff'] = [
      {
        'id': 'staff-001',
        'tenant_id': _tenantId,
        'user_id': 'staff-001',
        'email': 'manager@example.invalid',
        'role': 'owner',
        'status': 'active',
        'scopes': const <String>['*'],
      },
    ];
    _data['settings'] = [
      {
        'id': _tenantId,
        'tenant_id': _tenantId,
        'brand_name_ar': 'مناسكنا',
        'brand_name_en': 'Manasakna',
        'primary_locale': 'ar',
        'support_email': 'support@example.invalid',
        'support_phone': '+970000000000',
        'settings': const <String, dynamic>{},
      },
    ];
    for (final r in [
      'documents',
      'visas',
      'properties',
      'accommodation',
      'rooming',
      'flights',
      'transport',
      'ground_transport',
      'finance',
      'suppliers',
      'groups',
      'supervisors',
      'tasks',
      'support',
      'notifications',
    ]) {
      _data[r] = [];
    }
  }

  List<Map<String, dynamic>> _rows(String resource) =>
      _data.putIfAbsent(resource, () => <Map<String, dynamic>>[]);
  String _id(String resource) => '$resource-${_sequence++}';
  Map<String, dynamic> _upsert(
    String resource, {
    String? id,
    required Map<String, dynamic> payload,
  }) {
    final rows = _rows(resource);
    final index = id == null ? -1 : rows.indexWhere((r) => r['id'] == id);
    final row = <String, dynamic>{
      'id': id ?? _id(resource),
      'tenant_id': _tenantId,
      ...payload,
      'data_classification': payload['data_classification'] ?? 'synthetic',
    };
    if (index >= 0) {
      rows[index] = row;
    } else {
      rows.insert(0, row);
    }
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> list(
    String tenantId,
    String resource, {
    int limit = 100,
  }) async {
    if (tenantId != _tenantId) return const [];
    return _rows(resource)
        .where((r) => r['tenant_id'] == tenantId)
        .take(limit)
        .map(Map<String, dynamic>.from)
        .toList();
  }

  @override
  Future<Map<String, dynamic>> dashboard(String tenantId) async {
    if (tenantId != _tenantId) return const {};
    final bookings = _rows('bookings');
    return {
      'active_leads': _rows('leads').where((r) => r['status'] != 'lost').length,
      'open_quotes': _rows(
        'quotes',
      ).where((r) => r['status'] != 'accepted').length,
      'active_bookings': bookings
          .where((r) => r['workflow_stage'] != 'closed')
          .length,
      'upcoming_departures': _rows('departures').length,
      'missing_passports': _rows(
        'travelers',
      ).where((r) => r['readiness'] != 'ready').length,
      'open_tasks': _rows('tasks').length,
      'open_support': _rows('support').length,
      'customer_receivables': bookings.fold<num>(
        0,
        (sum, r) =>
            sum +
            ((r['total_amount'] ?? 0) as num) -
            ((r['paid_amount'] ?? 0) as num),
      ),
      'supplier_payables': 0,
    };
  }

  @override
  Future<Map<String, dynamic>> saveCustomer(
    String tenantId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _upsert('customers', id: id, payload: payload);
  @override
  Future<Map<String, dynamic>> saveLead(
    String tenantId,
    String customerId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _upsert(
    'leads',
    id: id,
    payload: {'customer_id': customerId, ...payload},
  );
  @override
  Future<Map<String, dynamic>> saveQuote(
    String tenantId,
    String leadId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _upsert(
    'quotes',
    id: id,
    payload: {
      'lead_id': leadId,
      'customer_id':
          payload['customer_id'] ??
          _rows('leads').firstWhere(
            (r) => r['id'] == leadId,
            orElse: () => {},
          )['customer_id'],
      ...payload,
    },
  );
  @override
  Future<Map<String, dynamic>> saveQuoteItem(
    String tenantId,
    String quoteId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _upsert(
    'quote_items',
    id: id,
    payload: {'quote_id': quoteId, ...payload},
  );
  @override
  Future<Map<String, dynamic>> saveBooking(
    String tenantId,
    String quoteId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async =>
      _upsert('bookings', id: id, payload: {'quote_id': quoteId, ...payload});
  @override
  Future<Map<String, dynamic>> saveTraveler(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _upsert(
    'travelers',
    id: id,
    payload: {'booking_id': bookingId, ...payload},
  );
  @override
  Future<Map<String, dynamic>> saveTask(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async =>
      _upsert('tasks', id: id, payload: {'booking_id': bookingId, ...payload});
  @override
  Future<Map<String, dynamic>> saveSupport(
    String tenantId,
    String bookingId, {
    String? id,
    required Map<String, dynamic> payload,
  }) async => _upsert(
    'support',
    id: id,
    payload: {'booking_id': bookingId, ...payload},
  );
  @override
  Future<Map<String, dynamic>> saveFinance(
    String tenantId,
    String bookingId,
    Map<String, dynamic> payload,
  ) async => _upsert('finance', payload: {'booking_id': bookingId, ...payload});
  @override
  Future<Map<String, dynamic>> updateStatus(
    String tenantId,
    String resource,
    String id,
    String status, {
    String? reason,
  }) async => _upsert(
    resource,
    id: id,
    payload: {'status': status, 'reason': ?reason},
  );
  @override
  Future<Map<String, dynamic>> advanceBooking(
    String tenantId,
    String bookingId,
    String stage, {
    String? reason,
    String? idempotencyKey,
  }) async => _upsert(
    'bookings',
    id: bookingId,
    payload: {
      'workflow_stage': stage,
      'transition_reason': ?reason,
    },
  );
  @override
  Future<Map<String, dynamic>> bookingReadiness(
    String tenantId,
    String bookingId,
  ) async {
    final travelers = _rows(
      'travelers',
    ).where((r) => r['booking_id'] == bookingId).toList();
    final booking = _rows(
      'bookings',
    ).firstWhere((r) => r['id'] == bookingId, orElse: () => {});
    final total = (booking['total_amount'] ?? 0) as num;
    final paid = (booking['paid_amount'] ?? 0) as num;
    return {
      'booking_id': bookingId,
      'traveler_count': travelers.length,
      'missing_documents': travelers
          .where((r) => r['readiness'] != 'ready')
          .length,
      'paid_amount': paid,
      'outstanding_amount': total - paid,
      'financially_ready': paid >= total,
      'operationally_ready':
          travelers.isNotEmpty &&
          travelers.every((r) => r['readiness'] == 'ready'),
    };
  }

  @override
  Future<Map<String, dynamic>> saveResource(
    String tenantId,
    String resource, {
    String? id,
    required Map<String, dynamic> payload,
  }) async {
    const allowed = {
      'packages',
      'departures',
      'documents',
      'visas',
      'properties',
      'accommodation',
      'rooming',
      'flights',
      'transport',
      'ground_transport',
      'suppliers',
      'groups',
      'supervisors',
      'notifications',
      'quote_items',
    };
    if (tenantId != _tenantId || !allowed.contains(resource)) {
      throw StateError('UNSUPPORTED_RESOURCE');
    }
    return _upsert(resource, id: id, payload: payload);
  }

  @override
  Future<Map<String, dynamic>> submitPublicLead(
    String tenantId,
    Map<String, dynamic> payload,
  ) async {
    final customer = await saveCustomer(
      tenantId,
      payload: {
        'full_name': payload['full_name'] ?? 'زائر تجريبي',
        'phone': payload['phone'],
        'email': payload['email'],
        'source_channel': 'public_web',
        'data_classification': 'synthetic',
      },
    );
    return saveLead(
      tenantId,
      customer['id'].toString(),
      payload: {
        'source': 'public_web',
        'notes': payload['message'] ?? '',
        'status': 'new',
        'data_classification': 'synthetic',
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> adminList(
    String tenantId,
    String resource,
  ) async {
    if (tenantId != _tenantId) return const [];
    const allowed = {'organizations', 'branches', 'staff', 'settings'};
    if (!allowed.contains(resource)) {
      throw StateError('UNSUPPORTED_ADMIN_RESOURCE');
    }
    return _rows(resource).map(Map<String, dynamic>.from).toList();
  }

  @override
  Future<Map<String, dynamic>> adminSave(
    String tenantId,
    String resource, {
    String? id,
    required Map<String, dynamic> payload,
  }) async {
    if (tenantId != _tenantId) throw StateError('TENANT_SCOPE_DENIED');
    if (resource == 'settings') {
      return _upsert('settings', id: _tenantId, payload: payload);
    }
    if (resource == 'branch') {
      return _upsert('branches', id: id, payload: payload);
    }
    if (resource == 'staff') {
      if (id == null) {
        throw StateError('STAFF_INVITATION_REQUIRES_AUTH_ADMIN_CHANNEL');
      }
      final current = _rows('staff').firstWhere(
        (row) => row['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      if (current.isEmpty) throw StateError('STAFF_NOT_IN_TENANT');
      return _upsert('staff', id: id, payload: {...current, ...payload});
    }
    throw StateError('UNSUPPORTED_ADMIN_RESOURCE');
  }

  @override
  Future<Map<String, dynamic>> entity360(
    String tenantId,
    String entity,
    String id,
  ) async {
    if (tenantId != _tenantId) throw StateError('TENANT_SCOPE_DENIED');
    Map<String, dynamic> record(String resource) => Map<String, dynamic>.from(
          _rows(resource).firstWhere(
            (row) => row['id'] == id,
            orElse: () => <String, dynamic>{},
          ),
        );
    List<Map<String, dynamic>> related(
      String resource,
      bool Function(Map<String, dynamic>) test,
    ) =>
        _rows(resource)
            .where(test)
            .map(Map<String, dynamic>.from)
            .toList(growable: false);

    if (entity == 'customer') {
      final current = record('customers');
      if (current.isEmpty) throw StateError('CUSTOMER_NOT_IN_TENANT');
      return {
        'entity': entity,
        'record': current,
        'sections': {
          'الفرص': related('leads', (r) => r['customer_id'] == id),
          'العروض': related('quotes', (r) => r['customer_id'] == id),
          'الحجوزات': related('bookings', (r) => r['customer_id'] == id),
        },
        'readiness': null,
      };
    }
    if (entity == 'booking') {
      final current = record('bookings');
      if (current.isEmpty) throw StateError('BOOKING_NOT_IN_TENANT');
      final travelerRows = related(
        'travelers',
        (r) => r['booking_id'] == id,
      );
      final travelerIds = travelerRows.map((r) => r['id']).toSet();
      return {
        'entity': entity,
        'record': current,
        'sections': {
          'المسافرون': travelerRows,
          'الوثائق': related(
            'documents',
            (r) => travelerIds.contains(r['traveler_id']),
          ),
          'التأشيرات': related(
            'visas',
            (r) => travelerIds.contains(r['traveler_id']),
          ),
          'الإقامة والغرف': related(
            'accommodation',
            (r) => r['booking_id'] == id,
          ),
          'الطيران': related('flights', (r) => r['booking_id'] == id),
          'النقل': related('transport', (r) => r['booking_id'] == id),
          'المالية': related('finance', (r) => r['booking_id'] == id),
          'المهام': related('tasks', (r) => r['booking_id'] == id),
          'الدعم': related('support', (r) => r['booking_id'] == id),
        },
        'readiness': await bookingReadiness(tenantId, id),
      };
    }
    if (entity == 'departure') {
      final current = record('departures');
      if (current.isEmpty) throw StateError('DEPARTURE_NOT_IN_TENANT');
      final groups = related('groups', (r) => r['departure_id'] == id);
      final groupIds = groups.map((r) => r['id']).toSet();
      return {
        'entity': entity,
        'record': current,
        'sections': {
          'الحجوزات': related('bookings', (r) => r['departure_id'] == id),
          'المجموعات': groups,
          'المشرفون': related(
            'supervisors',
            (r) => groupIds.contains(r['group_id']),
          ),
        },
        'readiness': null,
      };
    }
    throw StateError('UNSUPPORTED_360_ENTITY');
  }
}
