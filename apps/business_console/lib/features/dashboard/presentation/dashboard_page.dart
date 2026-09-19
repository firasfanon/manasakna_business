import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../commercial_mvp/presentation/commercial_mvp_page.dart';
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

    final branches = ref.watch(branchListProvider(selected.tenantId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('مناسكنا للأعمال'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () => Supabase.instance.client.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'لوحة الشركة',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'بيئة تجارية مستقلة للعمرة — لا تمنح أي سلطة سيادية في الحج.',
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            initialValue: selected.tenantId,
            decoration: const InputDecoration(
              labelText: 'الشركة / المستأجر',
              border: OutlineInputBorder(),
            ),
            items: memberships
                .map(
                  (item) => DropdownMenuItem(
                    value: item.tenantId,
                    child: Text(item.tenantName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              ref.read(selectedTenantIdProvider.notifier).state = value;
            },
          ),
          const SizedBox(height: 16),
          _AuthorityCard(membership: selected),
          const SizedBox(height: 16),
          _BranchCard(branches: branches),
          const SizedBox(height: 24),
          CommercialMvpPage(tenantId: selected.tenantId),
        ],
      ),
    );
  }
}

class _AuthorityCard extends StatelessWidget {
  const _AuthorityCard({required this.membership});

  final TenantMembership membership;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سياق الصلاحية',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('الدور: ${membership.role.name}'),
            Text('الخطة: ${membership.planCode ?? 'غير محددة'}'),
            Text('النطاقات الفعالة: ${membership.effectiveScopes.length}'),
            const SizedBox(height: 8),
            const Text(
              'صلاحيات الأهلية والقرعة والحصص والحالة الرسمية للحج محظورة هنا.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branches});

  final AsyncValue<List<Map<String, dynamic>>> branches;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: branches.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('تعذر تحميل الفروع: $error'),
          data: (items) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الفروع', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const Text('لا توجد فروع مسجلة.')
              else
                ...items.map(
                  (item) => ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(item['name']?.toString() ?? 'فرع'),
                    subtitle: Text(item['code']?.toString() ?? ''),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
