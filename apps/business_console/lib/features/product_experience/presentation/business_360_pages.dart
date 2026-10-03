import 'package:flutter/material.dart';

import '../../../core/design/manasakna_design_system.dart';

class Business360Page extends StatelessWidget {
  const Business360Page({
    super.key,
    required this.title,
    required this.record,
    this.sections = const {},
    this.readiness,
  });

  final String title;
  final Map<String, dynamic> record;
  final Map<String, List<Map<String, dynamic>>> sections;
  final Map<String, dynamic>? readiness;

  String _display(Object? value) {
    if (value == null || value.toString().trim().isEmpty) return '—';
    if (value is List) return value.join('، ');
    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join('، ');
    }
    return value.toString();
  }

  String _primary(Map<String, dynamic> row) {
    for (final key in const [
      'full_name',
      'name',
      'summary',
      'booking_code',
      'quote_code',
      'flight_number',
      'document_type',
      'code',
      'email',
      'id',
    ]) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'سجل مرتبط';
  }
  String _secondary(Map<String, dynamic> row) => row.entries
      .where(
        (e) =>
            !const {'id', 'tenant_id', 'created_by', 'updated_by'}
                .contains(e.key) &&
            e.value != null &&
            e.value.toString().isNotEmpty,
      )
      .take(4)
      .map((e) => '${e.key}: ${_display(e.value)}')
      .join(' • ');

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: ManasaknaDesign.panel(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _primary(record),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: record.entries
                        .where(
                          (e) =>
                              !const {'id', 'tenant_id'}.contains(e.key) &&
                              e.value != null &&
                              e.value.toString().isNotEmpty,
                        )
                        .take(10)
                        .map(
                          (e) => Chip(
                            label: Text('${e.key}: ${_display(e.value)}'),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            if (readiness != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: readiness!.entries
                        .map(
                          (e) => Chip(
                            avatar: e.value == true
                                ? const Icon(
                                    Icons.check_circle,
                                    color: ManasaknaDesign.success,
                                    size: 18,
                                  )
                                : null,
                            label: Text('${e.key}: ${_display(e.value)}'),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...sections.entries.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      section.key,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${section.value.length} سجل'),
                    children: section.value.isEmpty
                        ? const [
                            ListTile(
                              title: Text('لا توجد سجلات مرتبطة.'),
                            ),
                          ]
                        : section.value
                            .map(
                              (row) => ListTile(
                                leading: const Icon(Icons.link_outlined),
                                title: Text(_primary(row)),
                                subtitle: Text(
                                  _secondary(row),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class Customer360Page extends Business360Page {
  const Customer360Page({
    super.key,
    required super.record,
    super.sections,
  }) : super(title: 'ملف العميل 360°');
}

class Booking360Page extends Business360Page {
  const Booking360Page({
    super.key,
    required super.record,
    super.sections,
    super.readiness,
  }) : super(title: 'ملف الحجز 360°');
}

class Departure360Page extends Business360Page {
  const Departure360Page({
    super.key,
    required super.record,
    super.sections,
  }) : super(title: 'ملف المغادرة 360°');
}
