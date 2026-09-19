import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/tenant_context.dart';

abstract interface class BusinessRepository {
  Future<TenantContextEnvelope> currentContext();
  Future<List<Map<String, dynamic>>> listBranches(String tenantId);
}

class SupabaseBusinessRepository implements BusinessRepository {
  SupabaseBusinessRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TenantContextEnvelope> currentContext() async {
    final response = await _client.rpc('rpc_business_my_context_v1');
    if (response is! Map) {
      throw const FormatException('INVALID_BUSINESS_CONTEXT_RESPONSE');
    }
    return TenantContextEnvelope.fromJson(
      response.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listBranches(String tenantId) async {
    final response = await _client.rpc(
      'rpc_business_list_branches_v1',
      params: {'p_tenant_id': tenantId},
    );
    if (response is! List) {
      throw const FormatException('INVALID_BRANCH_LIST_RESPONSE');
    }
    return response
        .whereType<Map>()
        .map(
          (item) => item.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }
}
