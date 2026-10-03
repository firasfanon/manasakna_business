import 'package:flutter/material.dart';

import '../../../core/design/manasakna_design_system.dart';
import '../data/business_product_repository.dart';
import 'business_product_shell.dart';
import 'public_lead_capture_page.dart';
import 'traveler_portal_page.dart';

class ManasaknaPublicHomePage extends StatelessWidget {
  const ManasaknaPublicHomePage({
    super.key,
    required this.repository,
    this.tenantId = 'synthetic-tenant',
    this.tenantName = 'شركة العمرة التجريبية',
  });

  final BusinessProductRepository repository;
  final String tenantId;
  final String tenantName;

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.route_outlined),
        title: const Text('مناسكنا'),
        actions: [
          IconButton(
            tooltip: 'بوابة المسافر',
            onPressed: () => _open(
              context,
              TravelerPortalPage(repository: repository, tenantId: tenantId),
            ),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'دخول لوحة الأعمال',
            onPressed: () => _open(
              context,
              BusinessProductShell(
                tenantId: tenantId,
                tenantName: tenantName,
                repository: repository,
              ),
            ),
            icon: const Icon(Icons.dashboard_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SelectionArea(
        child: ListView(
          children: [
            _hero(context, compact),
            _trustStrip(context),
            _programs(context, compact),
            _journey(context, compact),
            _businessValue(context, compact),
            _cta(context),
            _footer(context),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, bool compact) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: compact ? 24 : 72,
      vertical: compact ? 52 : 88,
    ),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFFEAF5F0), Color(0xFFF7FAF8)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
    ),
    child: Wrap(
      spacing: 48,
      runSpacing: 32,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: compact ? double.infinity : 620,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Chip(label: Text('رحلة أوضح • متابعة أدق • خدمة أفضل')),
              const SizedBox(height: 20),
              Text(
                'رحلتك تبدأ بتنظيم أفضل',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: ManasaknaDesign.brandDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'اكتشف برامج العمرة، أرسل طلبك، وتابع رحلتك من الحجز حتى العودة ضمن تجربة رقمية واحدة.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  height: 1.7,
                  color: ManasaknaDesign.ink,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _open(
                      context,
                      PublicLeadCapturePage(
                        repository: repository,
                        tenantId: tenantId,
                      ),
                    ),
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('ابدأ طلب رحلتك'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _open(
                      context,
                      TravelerPortalPage(
                        repository: repository,
                        tenantId: tenantId,
                      ),
                    ),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('متابعة حجز قائم'),
                  ),
                  TextButton.icon(
                    onPressed: () => _open(
                      context,
                      BusinessProductShell(
                        tenantId: tenantId,
                        tenantName: tenantName,
                        repository: repository,
                      ),
                    ),
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const Text('دخول لوحة الأعمال'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: compact ? double.infinity : 420,
          padding: const EdgeInsets.all(24),
          decoration: ManasaknaDesign.panel(context),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مؤشر الرحلة',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 18),
              _JourneyStatus(label: 'الحجز', value: 'مؤكد', done: true),
              _JourneyStatus(
                label: 'الوثائق',
                value: 'قيد الاستكمال',
                done: false,
              ),
              _JourneyStatus(label: 'الفندق', value: 'مؤكد', done: true),
              _JourneyStatus(label: 'الطيران', value: 'مؤكد', done: true),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _trustStrip(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
    child: Wrap(
      spacing: 20,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _TrustItem(Icons.verified_user_outlined, 'حفظ منظم للبيانات'),
        _TrustItem(Icons.visibility_outlined, 'شفافية في حالة الرحلة'),
        _TrustItem(Icons.support_agent_outlined, 'متابعة ودعم'),
        _TrustItem(Icons.language_outlined, 'تجربة عربية متجاوبة'),
      ],
    ),
  );

  Widget _programs(BuildContext context, bool compact) => _section(
    context,
    title: 'البرامج المتاحة',
    subtitle: 'برامج مشتقة من مستودع المكتب الحالي في بيئة الاختبار.',
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: repository.list(tenantId, 'packages', limit: 12),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('تعذر تحميل البرامج: ${snapshot.error}'),
            ),
          );
        }
        final rows = snapshot.data ?? const <Map<String, dynamic>>[];
        if (rows.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('لا توجد برامج منشورة في مساحة الاختبار الحالية.'),
            ),
          );
        }
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: rows.map((row) {
            final name = row['name']?.toString() ?? 'برنامج عمرة';
            final days = row['duration_days']?.toString();
            final price = row['base_price'];
            final currency = row['currency']?.toString() ?? 'SAR';
            final detail = [
              if (days != null && days.isNotEmpty) '$days أيام',
              if (row['status'] != null) 'الحالة: ${row['status']}',
            ].join(' • ');
            final priceText = price == null
                ? 'السعر حسب تفاصيل البرنامج'
                : 'ابتداءً من $price $currency';
            return _ProgramCard(
              title: name,
              detail: detail.isEmpty
                  ? 'تفاصيل البرنامج متاحة عند الطلب'
                  : detail,
              price: priceText,
              onRequest: () => _open(
                context,
                PublicLeadCapturePage(
                  repository: repository,
                  tenantId: tenantId,
                  initialMessage: 'أرغب بالحصول على عرض للبرنامج: $name',
                ),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
  Widget _journey(BuildContext context, bool compact) => _section(
    context,
    title: 'رحلة واحدة، مراحل واضحة',
    subtitle: 'من طلب العرض حتى العودة، كل مرحلة مرتبطة بما قبلها وبعدها.',
    child: const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Step(1, 'طلب الرحلة'),
        _Step(2, 'العرض والحجز'),
        _Step(3, 'الوثائق والتأشيرة'),
        _Step(4, 'السكن والطيران والنقل'),
        _Step(5, 'الجاهزية والمغادرة'),
        _Step(6, 'العودة والتقييم'),
      ],
    ),
  );

  Widget _businessValue(BuildContext context, bool compact) => _section(
    context,
    title: 'منصة تشغيل للمكتب، وليست واجهة عرض فقط',
    subtitle:
        'مبيعات، حجوزات، مسافرون، عمليات، مالية، موردون وتقارير في سياق واحد.',
    child: const Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _ValueCard(
          Icons.hub_outlined,
          'عمليات مترابطة',
          'كل كيان مرتبط بسياقه التشغيلي.',
        ),
        _ValueCard(
          Icons.monitor_heart_outlined,
          'جاهزية لحظية',
          'رؤية النواقص قبل أن تتحول إلى مشكلة.',
        ),
        _ValueCard(
          Icons.query_stats_outlined,
          'قرارات أوضح',
          'مؤشرات مرتبطة بإجراءات قابلة للتنفيذ.',
        ),
      ],
    ),
  );
  Widget _cta(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ManasaknaDesign.brandDeep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 16,
        children: [
          const SizedBox(
            width: 560,
            child: Text(
              'هل تريد برنامجًا مناسبًا لعدد المسافرين وموعد السفر؟',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => _open(
              context,
              PublicLeadCapturePage(repository: repository, tenantId: tenantId),
            ),
            child: const Text('أرسل طلبك'),
          ),
        ],
      ),
    ),
  );

  Widget _footer(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: const Text(
      'مناسكنا • بيئة تطوير غير إنتاجية • لا تستخدم بيانات مستخدمين حقيقية',
      textAlign: TextAlign.center,
    ),
  );
  Widget _section(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
  }) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    ),
  );
}

class _JourneyStatus extends StatelessWidget {
  const _JourneyStatus({
    required this.label,
    required this.value,
    required this.done,
  });
  final String label;
  final String value;
  final bool done;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      done ? Icons.check_circle : Icons.timelapse,
      color: done ? ManasaknaDesign.success : ManasaknaDesign.warning,
    ),
    title: Text(label),
    trailing: Text(value),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) =>
      Chip(avatar: Icon(icon, size: 18), label: Text(label));
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.title,
    required this.detail,
    required this.price,
    required this.onRequest,
  });
  final String title;
  final String detail;
  final String price;
  final VoidCallback onRequest;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 350,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.mosque_outlined, color: ManasaknaDesign.brand),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(detail),
            const SizedBox(height: 16),
            Text(
              price,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: ManasaknaDesign.brandDeep,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRequest,
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('اطلب عرضًا'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.label);
  final int number;
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: CircleAvatar(child: Text('$number')),
    label: Text(label),
  );
}

class _ValueCard extends StatelessWidget {
  const _ValueCard(this.icon, this.title, this.detail);
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 350,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ManasaknaDesign.brand),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(detail),
          ],
        ),
      ),
    ),
  );
}
