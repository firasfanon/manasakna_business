import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/commercial_mvp_models.dart';
import 'commercial_mvp_providers.dart';

class CommercialMvpPage extends ConsumerWidget {
  const CommercialMvpPage({required this.tenantId, super.key});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(commercialPipelineProvider(tenantId));
    final bookings = ref.watch(commercialBookingsProvider(tenantId));
    final selectedBookingId = ref.watch(
      selectedCommercialBookingProvider(tenantId),
    );

    AsyncValue<CommercialJourneyContext>? journey;
    if (selectedBookingId != null) {
      journey = ref.watch(
        commercialJourneyContextProvider((
          tenantId: tenantId,
          bookingId: selectedBookingId,
        )),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تشغيل العمرة التجاري',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        const Text(
          'Lead → Quote → Booking → Traveler → Visa → Payment → Trip Operations → Journey Context',
        ),
        const SizedBox(height: 16),
        summary.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) =>
              _ErrorCard(title: 'تعذر تحميل مؤشرات التشغيل', error: error),
          data: (data) => _PipelineCards(summary: data),
        ),
        const SizedBox(height: 16),
        const _ModuleMap(modules: commercialMvpModules),
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
                        selectedCommercialBookingProvider(tenantId).notifier,
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
            error: (error, _) => _ErrorCard(
              title: 'تعذر بناء Commercial Journey Context',
              error: error,
            ),
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
      ('Leads', summary.leads, Icons.person_search_outlined),
      ('العروض', summary.quotes, Icons.request_quote_outlined),
      ('الحجوزات', summary.bookings, Icons.confirmation_number_outlined),
      ('المسافرون', summary.travelers, Icons.groups_outlined),
      ('المغادرات', summary.departures, Icons.flight_takeoff_outlined),
      ('دعم مفتوح', summary.openSupport, Icons.support_agent_outlined),
      ('مهام مفتوحة', summary.openTasks, Icons.task_alt_outlined),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map(
            (item) => SizedBox(
              width: 180,
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
                              style: Theme.of(context).textTheme.headlineSmall,
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
  }
}

class _ModuleMap extends StatelessWidget {
  const _ModuleMap({required this.modules});

  final List<CommercialModule> modules;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'خريطة MVP التشغيلية',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: modules
                  .map(
                    (module) => Tooltip(
                      message: module.description,
                      child: Chip(
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                        ),
                        label: Text(module.label),
                      ),
                    ),
                  )
                  .toList(growable: false),
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
                'لا توجد بيانات تشغيل حقيقية. اختبارات G7 تستخدم بيانات اصطناعية وتعمل داخل معاملات يتم التراجع عنها.',
              )
            else ...[
              DropdownButtonFormField<String>(
                initialValue: selectedBookingId,
                decoration: const InputDecoration(
                  labelText: 'اختر حجزًا لمعاينة Journey Context',
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
              'Commercial Umrah Journey Context',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _line('Schema', contextData.schemaVersion),
            _line('Authority', contextData.sourceAuthority),
            _line('Tenant', contextData.tenantName),
            _line('Booking', contextData.bookingCode),
            _line('Package', contextData.packageName),
            _line('Travelers', contextData.travelerCount.toString()),
            _line('Flights', contextData.flightCount.toString()),
            _line('Room', contextData.roomLabel),
            _line('Freshness', contextData.freshness),
            const SizedBox(height: 10),
            const Text(
              'هذا السياق تجاري للعمرة فقط ولا يحمل أي أهلية أو قرعة أو حصة أو حالة حج رسمية.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text('$label: $value'),
    );
  }
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

class CommercialMvpOverviewPreview extends StatelessWidget {
  const CommercialMvpOverviewPreview({super.key});

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
        _ModuleMap(modules: commercialMvpModules),
      ],
    );
  }
}

class CommercialMvpBrowserPreviewPage extends StatelessWidget {
  const CommercialMvpBrowserPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مناسكنا للأعمال — Phase 7 Preview')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: CommercialMvpOverviewPreview(),
      ),
    );
  }
}
