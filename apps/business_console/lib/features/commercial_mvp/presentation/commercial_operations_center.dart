import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/commercial_mvp_models.dart';
import '../../official_external_integrations/domain/phase12_external_integration_readiness.dart';
import 'commercial_mvp_providers.dart';

class CommercialOperationsCenter extends ConsumerStatefulWidget {
  const CommercialOperationsCenter({required this.tenantId, super.key});

  final String tenantId;

  @override
  ConsumerState<CommercialOperationsCenter> createState() =>
      _CommercialOperationsCenterState();
}

class _CommercialOperationsCenterState
    extends ConsumerState<CommercialOperationsCenter> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(commercialPipelineProvider(widget.tenantId));
    final bookings = ref.watch(commercialBookingsProvider(widget.tenantId));
    final selectedBookingId = ref.watch(
      selectedCommercialBookingProvider(widget.tenantId),
    );

    AsyncValue<CommercialJourneyContext>? journey;
    if (selectedBookingId != null) {
      journey = ref.watch(
        commercialJourneyContextProvider((
          tenantId: widget.tenantId,
          bookingId: selectedBookingId,
        )),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مركز عمليات العمرة',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'إدارة رحلة العميل من الاستفسار حتى العودة ضمن صلاحيات الشركة التجارية.',
        ),
        const SizedBox(height: 16),
        summary.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) =>
              _ErrorCard(title: 'تعذر تحميل مؤشرات التشغيل', error: error),
          data: (data) => _PipelineCards(summary: data),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            labelText: 'البحث في الوحدات التشغيلية',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        _OperationsModuleGrid(query: query),
        const SizedBox(height: 16),
        const _ExternalIntegrationReadinessCard(),
        const SizedBox(height: 16),
        bookings.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) =>
              _ErrorCard(title: 'تعذر تحميل الحجوزات', error: error),
          data: (items) => _BookingsCard(
            bookings: items,
            selectedBookingId: selectedBookingId,
            onSelected: (value) {
              ref
                      .read(
                        selectedCommercialBookingProvider(
                          widget.tenantId,
                        ).notifier,
                      )
                      .state =
                  value;
            },
          ),
        ),
        if (journey != null) ...[
          const SizedBox(height: 16),
          journey.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) =>
                _ErrorCard(title: 'تعذر بناء سياق رحلة العمرة', error: error),
            data: (data) => _JourneyContextCard(contextData: data),
          ),
        ],
      ],
    );
  }
}

class _PipelineCards extends StatelessWidget {
  const _PipelineCards({required this.summary});

  final PipelineSummary summary;

  @override
  Widget build(BuildContext context) {
    final cards = <(String, int, IconData)>[
      ('العملاء المحتملون', summary.leads, Icons.person_search_outlined),
      ('العروض', summary.quotes, Icons.request_quote_outlined),
      ('الحجوزات', summary.bookings, Icons.confirmation_number_outlined),
      ('المسافرون', summary.travelers, Icons.groups_outlined),
      ('المغادرات', summary.departures, Icons.flight_takeoff_outlined),
      ('الدعم المفتوح', summary.openSupport, Icons.support_agent_outlined),
      ('المهام المفتوحة', summary.openTasks, Icons.task_alt_outlined),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width >= 900
            ? 180.0
            : width >= 520
            ? (width - 12) / 2
            : width;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map(
                (item) => SizedBox(
                  width: cardWidth,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(item.$3),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.$2.toString(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                Text(item.$1),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _OperationsModuleGrid extends StatelessWidget {
  const _OperationsModuleGrid({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final normalized = query.trim().toLowerCase();
    final modules = commercialMvpModules
        .where(
          (module) =>
              normalized.isEmpty ||
              module.label.toLowerCase().contains(normalized) ||
              module.description.toLowerCase().contains(normalized),
        )
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الوحدات التشغيلية',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'كل وحدة تعرض حالتها الحقيقية. الوظائف المؤجلة لا تُعرض كوظائف إنتاجية مكتملة.',
            ),
            const SizedBox(height: 12),
            if (modules.isEmpty)
              const Text('لا توجد وحدة مطابقة للبحث.')
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final cardWidth = width >= 1000
                      ? 300.0
                      : width >= 650
                      ? 260.0
                      : width;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: modules
                        .map(
                          (module) => SizedBox(
                            width: cardWidth,
                            child: _ModuleCard(module: module),
                          ),
                        )
                        .toList(growable: false),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ModuleStateChip extends StatelessWidget {
  const _ModuleStateChip({required this.state});

  final CommercialModuleState state;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (state) {
      CommercialModuleState.preproductionReady => (
        'جاهز قبل الإنتاج',
        Icons.verified_outlined,
      ),
      CommercialModuleState.syntheticOnly => (
        'بيانات اصطناعية',
        Icons.science_outlined,
      ),
      CommercialModuleState.deferred => ('مؤجل', Icons.schedule_outlined),
    };

    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final CommercialModule module;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.apps_outlined),
                Text(
                  module.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _ModuleStateChip(state: module.state),
              ],
            ),
            const SizedBox(height: 8),
            Text(module.description),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Chip(label: Text('قائمة')),
                Chip(label: Text('تفاصيل')),
                Chip(label: Text('بحث/تصفية')),
                Chip(label: Text('حالات')),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showModuleWorkspace(context, module),
                icon: const Icon(Icons.open_in_new),
                label: const Text('فتح مساحة الوحدة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showModuleWorkspace(BuildContext context, CommercialModule module) {
  showDialog<void>(
    context: context,
    builder: (context) => _ModuleWorkspaceDialog(module: module),
  );
}

class _ModuleWorkspaceDialog extends StatefulWidget {
  const _ModuleWorkspaceDialog({required this.module});

  final CommercialModule module;

  @override
  State<_ModuleWorkspaceDialog> createState() => _ModuleWorkspaceDialogState();
}

class _ModuleWorkspaceDialogState extends State<_ModuleWorkspaceDialog> {
  final List<_SyntheticRecord> records = [
    _SyntheticRecord('SYN-001', 'سجل اختبار أول', 'قيد المتابعة'),
    _SyntheticRecord('SYN-002', 'سجل اختبار ثان', 'مكتمل'),
  ];
  String query = '';

  @override
  Widget build(BuildContext context) {
    final visible = records
        .where(
          (record) =>
              query.isEmpty ||
              record.code.toLowerCase().contains(query.toLowerCase()) ||
              record.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList(growable: false);

    return AlertDialog(
      title: Text(widget.module.label),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.module.description),
              const SizedBox(height: 8),
              const Text(
                'مساحة تشغيل داخلية غير إنتاجية — بيانات اصطناعية فقط.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  labelText: 'بحث',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                const Text('لا توجد سجلات مطابقة.')
              else
                ...visible.map(
                  (record) => Card.outlined(
                    child: ListTile(
                      title: Text(record.title),
                      subtitle: Text(record.code),
                      trailing: DropdownButton<String>(
                        value: record.status,
                        items: const [
                          DropdownMenuItem(
                            value: 'قيد المتابعة',
                            child: Text('قيد المتابعة'),
                          ),
                          DropdownMenuItem(
                            value: 'مكتمل',
                            child: Text('مكتمل'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => record.status = value);
                        },
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    records.add(
                      _SyntheticRecord(
                        'SYN-${(records.length + 1).toString().padLeft(3, '0')}',
                        'سجل اختبار جديد',
                        'قيد المتابعة',
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة سجل تجريبي'),
              ),
              const SizedBox(height: 8),
              const Text(
                'بيانات الأعمال تم التحقق منها على Supabase غير إنتاجي. بقية المزودين تبقى مؤجلة حتى تتوفر بيئات Sandbox رسمية، ولا يوجد أي Production fallback.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

class _SyntheticRecord {
  _SyntheticRecord(this.code, this.title, this.status);

  final String code;
  final String title;
  String status;
}

class _ExternalIntegrationReadinessCard extends StatelessWidget {
  const _ExternalIntegrationReadinessCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حالة التكاملات الخارجية',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'لا يوجد أي اتصال إنتاجي. تم التحقق من طبقة بيانات الأعمال غير الإنتاجية فقط؛ بقية النطاقات تبقى مؤجلة حتى تتوفر Sandbox رسمية.',
            ),
            const SizedBox(height: 12),
            ...phase12ExternalIntegrationReadiness.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.verifiedNonProduction
                      ? Icons.verified_outlined
                      : Icons.pause_circle_outline,
                ),
                title: Text(item.labelAr),
                subtitle: Text(item.reasonAr),
                trailing: Chip(
                  label: Text(
                    item.verifiedNonProduction ? 'متحقق — غير إنتاجي' : 'مؤجل',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingsCard extends StatelessWidget {
  const _BookingsCard({
    required this.bookings,
    required this.selectedBookingId,
    required this.onSelected,
  });

  final List<CommercialBookingSummary> bookings;
  final String? selectedBookingId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الحجوزات وسياق الرحلة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (bookings.isEmpty)
              const Text(
                'لا توجد حجوزات في مصدر البيانات الحالي. حالة المصدر معروضة كما هي دون إنشاء بيانات وهمية.',
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: selectedBookingId,
                decoration: const InputDecoration(
                  labelText: 'اختر حجزًا لعرض سياق الرحلة',
                  border: OutlineInputBorder(),
                ),
                items: bookings
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.bookingCode} — ${item.customerName}',
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onSelected,
              ),
              const SizedBox(height: 12),
              ...bookings
                  .take(5)
                  .map(
                    (item) => ListTile(
                      leading: const Icon(Icons.card_travel_outlined),
                      title: Text(item.bookingCode),
                      subtitle: Text(
                        '${item.customerName} • ${item.packageName} • ${item.departureStart}',
                      ),
                      trailing: Text(item.status),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JourneyContextCard extends StatelessWidget {
  const _JourneyContextCard({required this.contextData});

  final CommercialJourneyContext contextData;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سياق رحلة العمرة',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _line('الإصدار', contextData.schemaVersion),
            _line('السلطة المصدرية', contextData.sourceAuthority),
            _line('الشركة', contextData.tenantName),
            _line('الحجز', contextData.bookingCode),
            _line('الباقة', contextData.packageName),
            _line('المسافرون', contextData.travelerCount.toString()),
            _line('الرحلات الجوية', contextData.flightCount.toString()),
            _line('الغرفة', contextData.roomLabel),
            _line('حداثة البيانات', contextData.freshness),
            const SizedBox(height: 10),
            const Text(
              'هذا السياق تجاري للعمرة فقط ولا يمنح أهلية أو قرعة أو حصة أو حالة حج رسمية.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text('$label: $value'),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.title, required this.error});

  final String title;
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('$title\n$error'),
      ),
    );
  }
}

class CommercialOperationsSyntheticOverview extends StatelessWidget {
  const CommercialOperationsSyntheticOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PipelineCards(
          summary: PipelineSummary(
            leads: 2,
            quotes: 2,
            bookings: 2,
            travelers: 2,
            departures: 2,
            openSupport: 1,
            openTasks: 1,
          ),
        ),
        SizedBox(height: 16),
        _OperationsModuleGrid(query: ''),
        SizedBox(height: 16),
        _ExternalIntegrationReadinessCard(),
      ],
    );
  }
}

class CommercialOperationsSyntheticPage extends StatelessWidget {
  const CommercialOperationsSyntheticPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مناسكنا للأعمال — بيئة اختبار داخلية',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 520 ? 12.0 : 24.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 24,
              ),
              child: SizedBox(
                width: constraints.maxWidth - (horizontalPadding * 2),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'بيانات اصطناعية فقط — لا معاملات إنتاجية ولا صلاحيات حج سيادية.',
                    ),
                    SizedBox(height: 16),
                    CommercialOperationsSyntheticOverview(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
