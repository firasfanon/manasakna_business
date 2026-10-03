import 'package:flutter/material.dart';

import '../../../core/design/manasakna_design_system.dart';
import '../data/business_product_repository.dart';

class BusinessSearchSelection {
  const BusinessSearchSelection(this.resource, this.row);
  final String resource;
  final Map<String, dynamic> row;
}

class GlobalBusinessSearchPage extends StatefulWidget {
  const GlobalBusinessSearchPage({
    super.key,
    required this.repository,
    required this.tenantId,
  });

  final BusinessProductRepository repository;
  final String tenantId;

  @override
  State<GlobalBusinessSearchPage> createState() =>
      _GlobalBusinessSearchPageState();
}

class _GlobalBusinessSearchPageState extends State<GlobalBusinessSearchPage> {
  static const _resources = <String>[
    'customers',
    'leads',
    'quotes',
    'bookings',
    'travelers',
    'packages',
    'departures',
    'suppliers',
    'groups',
    'tasks',
    'support',
  ];

  late Future<List<BusinessSearchSelection>> _request;
  String query = '';

  @override
  void initState() {
    super.initState();
    _request = _load();
  }

  Future<List<BusinessSearchSelection>> _load() async {
    final rows = <BusinessSearchSelection>[];
    for (final resource in _resources) {
      try {
        final items = await widget.repository.list(
          widget.tenantId,
          resource,
          limit: 100,
        );
        rows.addAll(items.map((row) => BusinessSearchSelection(resource, row)));
      } catch (_) {
        // Search remains bounded by the caller's actual server-side scopes.
      }
    }
    return rows;
  }

  String _title(Map<String, dynamic> row) {
    for (final key in const [
      'full_name',
      'name',
      'booking_code',
      'quote_code',
      'customer_code',
      'traveler_code',
      'case_code',
      'title',
      'summary',
      'reference',
      'id',
    ]) {
      final value = row[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return 'سجل';
  }

  String _resourceLabel(String resource) => switch (resource) {
    'customers' => 'العملاء',
    'leads' => 'الفرص',
    'quotes' => 'العروض',
    'bookings' => 'الحجوزات',
    'travelers' => 'المسافرون',
    'packages' => 'البرامج',
    'departures' => 'المغادرات',
    'suppliers' => 'الموردون',
    'groups' => 'المجموعات',
    'tasks' => 'المهام',
    'support' => 'الدعم',
    _ => resource,
  };
  bool _matches(BusinessSearchSelection item) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (_resourceLabel(item.resource).toLowerCase().contains(q)) return true;
    return item.row.values.any(
      (value) => value?.toString().toLowerCase().contains(q) == true,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('البحث الشامل')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'عميل، حجز، مسافر، برنامج، مورد أو مهمة',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<BusinessSearchSelection>>(
              future: _request,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('تعذر تحميل البحث: ${snapshot.error}'),
                  );
                }
                final rows = (snapshot.data ?? const [])
                    .where(_matches)
                    .take(100)
                    .toList();
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('لا توجد نتائج ضمن الصلاحيات الحالية.'),
                  );
                }
                return ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = rows[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.manage_search,
                        color: ManasaknaDesign.brand,
                      ),
                      title: Text(_title(item.row)),
                      subtitle: Text(_resourceLabel(item.resource)),
                      trailing: const Icon(Icons.arrow_back),
                      onTap: () => Navigator.pop(context, item),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
