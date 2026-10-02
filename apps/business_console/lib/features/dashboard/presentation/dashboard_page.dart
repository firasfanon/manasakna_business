import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../product_experience/data/business_product_repository.dart';
import '../../product_experience/presentation/business_product_shell.dart';
import '../../tenancy/domain/tenant_context.dart';
import '../../tenancy/presentation/tenant_session.dart';

class BusinessDashboardPage extends ConsumerWidget {
  const BusinessDashboardPage({required this.contextEnvelope, super.key});
  final TenantContextEnvelope contextEnvelope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = contextEnvelope.activeMemberships;
    if (memberships.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('لا توجد عضوية تجارية فعالة لهذا الحساب.')),
      );
    }
    final selectedId = ref.watch(selectedTenantIdProvider);
    final selected = memberships.firstWhere(
      (item) => item.tenantId == selectedId,
      orElse: () => memberships.first,
    );
    return BusinessProductShell(
      tenantId: selected.tenantId,
      tenantName: selected.tenantName,
      repository: SupabaseBusinessProductRepository(Supabase.instance.client),
      nonProduction: true,
      onSignOut: () => Supabase.instance.client.auth.signOut(),
    );
  }
}
