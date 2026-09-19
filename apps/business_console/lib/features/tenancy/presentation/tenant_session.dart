import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/business_repository.dart';
import '../domain/tenant_context.dart';

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return SupabaseBusinessRepository(Supabase.instance.client);
});

final businessContextProvider = FutureProvider<TenantContextEnvelope>((ref) {
  return ref.watch(businessRepositoryProvider).currentContext();
});

final selectedTenantIdProvider = StateProvider<String?>((ref) => null);

final branchListProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tenantId) {
      return ref.watch(businessRepositoryProvider).listBranches(tenantId);
    });
