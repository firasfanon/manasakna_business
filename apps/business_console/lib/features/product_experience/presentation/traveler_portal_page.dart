import 'package:flutter/material.dart';

import '../../../core/design/manasakna_design_system.dart';
import '../data/business_product_repository.dart';

class TravelerPortalPage extends StatefulWidget {
  const TravelerPortalPage({
    super.key,
    required this.repository,
    this.tenantId = 'synthetic-tenant',
  });
  final BusinessProductRepository repository;
  final String tenantId;

  @override
  State<TravelerPortalPage> createState() => _TravelerPortalPageState();
}

class _TravelerPortalPageState extends State<TravelerPortalPage> {
  late Future<List<Map<String, dynamic>>> _bookings;
  String? _selectedBookingId;

  @override
  void initState() {
    super.initState();
    _bookings = widget.repository.list(widget.tenantId, 'bookings');
  }

  void _reload() => setState(() {
    _bookings = widget.repository.list(widget.tenantId, 'bookings');
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('بوابة المسافر'),
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _bookings,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('تعذر تحميل رحلة المسافر: ${snapshot.error}'),
            ),
          );
        }
        final bookings = snapshot.data ?? const <Map<String, dynamic>>[];
        Map<String, dynamic>? booking;
        if (bookings.isNotEmpty) {
          booking = bookings.firstWhere(
            (row) => row['id']?.toString() == _selectedBookingId,
            orElse: () => bookings.first,
          );
          _selectedBookingId ??= booking['id']?.toString();
        }
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (bookings.length > 1) ...[
              _bookingSelector(bookings),
              const SizedBox(height: 18),
            ],
            _hero(context, booking),
            const SizedBox(height: 18),
            _journey(context, booking),
            const SizedBox(height: 18),
            _services(context),
            if (booking != null) ...[
              const SizedBox(height: 18),
              _bookingOverview(context, booking),
            ],
          ],
        );
      },
    ),
  );
  Widget _bookingSelector(List<Map<String, dynamic>> bookings) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختر الحجز',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bookings
                .map(
                  (row) => ChoiceChip(
                    selected: row['id']?.toString() == _selectedBookingId,
                    label: Text(
                      row['booking_code']?.toString() ??
                          row['code']?.toString() ??
                          'حجز',
                    ),
                    onSelected: (_) => setState(
                      () => _selectedBookingId = row['id']?.toString(),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    ),
  );

  Widget _bookingOverview(
    BuildContext context,
    Map<String, dynamic> booking,
  ) => FutureBuilder<Map<String, dynamic>>(
    future: widget.repository.entity360(
      widget.tenantId,
      'booking',
      booking['id'].toString(),
    ),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          ),
        );
      }
      if (snapshot.hasError) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('تعذر تحميل تفاصيل الحجز: ${snapshot.error}'),
          ),
        );
      }
      final envelope = snapshot.data ?? const <String, dynamic>{};
      final sectionsRaw = envelope['sections'];
      final sections = sectionsRaw is Map
          ? sectionsRaw.map((k, v) => MapEntry(k.toString(), v))
          : const <String, dynamic>{};
      final readinessRaw = envelope['readiness'];
      final readiness = readinessRaw is Map
          ? readinessRaw.map((k, v) => MapEntry(k.toString(), v))
          : const <String, dynamic>{};

      int countOf(String key) {
        final value = sections[key];
        return value is List ? value.length : 0;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ملخص الحجز',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryCard(
                Icons.groups_outlined,
                'المسافرون',
                '${countOf('المسافرون')}',
              ),
              _SummaryCard(
                Icons.badge_outlined,
                'الوثائق',
                '${countOf('الوثائق')}',
              ),
              _SummaryCard(
                Icons.approval_outlined,
                'التأشيرات',
                '${countOf('التأشيرات')}',
              ),
              _SummaryCard(
                Icons.hotel_outlined,
                'الإقامة',
                '${countOf('الإقامة والغرف')}',
              ),
              _SummaryCard(
                Icons.flight_outlined,
                'الطيران',
                '${countOf('الطيران')}',
              ),
              _SummaryCard(
                Icons.directions_bus_outlined,
                'النقل',
                '${countOf('النقل')}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              leading: Icon(
                readiness['operationally_ready'] == true
                    ? Icons.check_circle
                    : Icons.rule_folder_outlined,
                color: readiness['operationally_ready'] == true
                    ? ManasaknaDesign.success
                    : ManasaknaDesign.warning,
              ),
              title: const Text('الجاهزية التشغيلية'),
              subtitle: Text(
                readiness['operationally_ready'] == true
                    ? 'متطلبات الرحلة الأساسية مكتملة حسب السجل الحالي.'
                    : 'توجد متطلبات غير مكتملة؛ راجع الوثائق والدفعات والخدمات.',
              ),
              trailing: readiness['outstanding_amount'] == null
                  ? null
                  : Text('المتبقي: ${readiness['outstanding_amount']}'),
            ),
          ),
        ],
      );
    },
  );

  Widget _hero(
    BuildContext context,
    Map<String, dynamic>? booking,
  ) => Container(
    padding: const EdgeInsets.all(24),
    decoration: ManasaknaDesign.panel(context),
    child: Wrap(
      spacing: 24,
      runSpacing: 16,
      alignment: WrapAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Chip(label: Text('بيئة اختبار — لا توجد بيانات حقيقية')),
              const SizedBox(height: 12),
              Text(
                booking == null
                    ? 'لا يوجد حجز تجريبي مرتبط'
                    : 'رحلتك ${booking['booking_code'] ?? booking['code'] ?? ''}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                booking == null
                    ? 'يمكن ربط البوابة بحجز مؤكد ضمن بيئة الاختبار.'
                    : 'تابع الجاهزية، المستندات، الدفعات وتفاصيل الرحلة من مكان واحد.',
              ),
            ],
          ),
        ),
        if (booking != null)
          FutureBuilder<Map<String, dynamic>>(
            future: widget.repository.bookingReadiness(
              widget.tenantId,
              booking['id'].toString(),
            ),
            builder: (context, snapshot) {
              final ready = snapshot.data?['operationally_ready'] == true;
              return Chip(
                avatar: Icon(
                  ready ? Icons.check_circle : Icons.timelapse,
                  color: ready
                      ? ManasaknaDesign.success
                      : ManasaknaDesign.warning,
                ),
                label: Text(
                  ready ? 'جاهز تشغيليًا' : 'توجد عناصر تحتاج استكمالًا',
                ),
              );
            },
          ),
      ],
    ),
  );

  Widget _journey(BuildContext context, Map<String, dynamic>? booking) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مسار الرحلة',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _JourneyChip('الحجز', Icons.confirmation_number_outlined, true),
              _JourneyChip('المسافرون', Icons.groups_outlined, true),
              _JourneyChip('الوثائق', Icons.badge_outlined, false),
              _JourneyChip('التأشيرة', Icons.approval_outlined, false),
              _JourneyChip('السكن', Icons.hotel_outlined, true),
              _JourneyChip('الطيران', Icons.flight_outlined, true),
              _JourneyChip('النقل', Icons.directions_bus_outlined, false),
              _JourneyChip('المغادرة', Icons.luggage_outlined, false),
            ],
          ),
        ],
      ),
    ),
  );
  Widget _services(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final cardWidth = compact ? 165.0 : 320.0;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        _PortalAction(
          cardWidth,
          Icons.badge_outlined,
          'المستندات',
          'الجواز والتأشيرة والمتطلبات',
        ),
        _PortalAction(
          cardWidth,
          Icons.payments_outlined,
          'الدفعات',
          'المدفوع والمتبقي وحالة السداد',
        ),
        _PortalAction(
          cardWidth,
          Icons.hotel_outlined,
          'الإقامة',
          'الفندق والغرفة ومواعيد الدخول',
        ),
        _PortalAction(
          cardWidth,
          Icons.flight_takeoff_outlined,
          'الطيران',
          'مقاطع الرحلة ومعلومات المغادرة',
        ),
        _PortalAction(
          cardWidth,
          Icons.directions_bus_outlined,
          'النقل',
          'التجمع والنقل الأرضي',
        ),
        _PortalAction(
          cardWidth,
          Icons.support_agent_outlined,
          'الدعم',
          'تواصل مع فريق المكتب',
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: ManasaknaDesign.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _JourneyChip extends StatelessWidget {
  const _JourneyChip(this.label, this.icon, this.done);
  final String label;
  final IconData icon;
  final bool done;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 18),
    label: Text(done ? '$label ✓' : label),
  );
}

class _PortalAction extends StatelessWidget {
  const _PortalAction(this.width, this.icon, this.title, this.subtitle);
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: ListTile(
        leading: Icon(icon, color: ManasaknaDesign.brand),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    ),
  );
}
