import 'package:flutter/material.dart';

import '../../../core/design/manasakna_design_system.dart';
import '../data/business_product_repository.dart';

class BusinessInsightsPage extends StatefulWidget {
  const BusinessInsightsPage({
    super.key,
    required this.repository,
    required this.tenantId,
    required this.roleName,
    this.initialTab = 0,
  });

  final BusinessProductRepository repository;
  final String tenantId;
  final String roleName;
  final int initialTab;

  @override
  State<BusinessInsightsPage> createState() => _BusinessInsightsPageState();
}

class _BusinessInsightsPageState extends State<BusinessInsightsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late Future<_InsightsEnvelope> _request;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _request = _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<_InsightsEnvelope> _load() async {
    final dashboard = await widget.repository.dashboard(widget.tenantId);
    Future<List<Map<String, dynamic>>> safeList(String resource) async {
      try {
        return await widget.repository.list(
          widget.tenantId,
          resource,
          limit: 100,
        );
      } catch (_) {
        return const <Map<String, dynamic>>[];
      }
    }

    final tasks = await safeList('tasks');
    final support = await safeList('support');
    final bookings = await safeList('bookings');
    final travelers = await safeList('travelers');
    final departures = await safeList('departures');
    return _InsightsEnvelope(
      dashboard: dashboard,
      tasks: tasks,
      support: support,
      bookings: bookings,
      travelers: travelers,
      departures: departures,
    );
  }

  void _reload() => setState(() => _request = _load());

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('مركز القيادة والذكاء التشغيلي'),
      bottom: TabBar(
        controller: _tabs,
        tabs: const [
          Tab(
            icon: Icon(Icons.notifications_active_outlined),
            text: 'الإجراءات',
          ),
          Tab(
            icon: Icon(Icons.auto_awesome_outlined),
            text: 'Manasakna Intelligence',
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: FutureBuilder<_InsightsEnvelope>(
      future: _request,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('تعذر تحميل مركز القيادة: ${snapshot.error}'),
            ),
          );
        }
        final data = snapshot.data!;
        return TabBarView(
          controller: _tabs,
          children: [_actionCenter(data), _intelligence(data)],
        );
      },
    ),
  );
  Widget _actionCenter(_InsightsEnvelope data) {
    final alerts = <_ActionSignal>[];
    final missingPassports =
        (data.dashboard['missing_passports'] as num?)?.toInt() ?? 0;
    final receivables = (data.dashboard['customer_receivables'] as num?) ?? 0;

    if (missingPassports > 0) {
      alerts.add(
        _ActionSignal(
          severity: _Severity.urgent,
          icon: Icons.badge_outlined,
          title: 'وثائق مسافرين تحتاج متابعة',
          detail: '$missingPassports عنصرًا غير جاهز حسب مؤشرات المكتب.',
          resource: 'documents',
        ),
      );
    }
    final openTasks = data.tasks
        .where((row) => !{'done', 'cancelled'}.contains(row['status']))
        .length;
    if (openTasks > 0) {
      alerts.add(
        _ActionSignal(
          severity: _Severity.warning,
          icon: Icons.task_alt_outlined,
          title: 'مهام تشغيلية مفتوحة',
          detail: '$openTasks مهمة ما زالت بحاجة إلى إجراء.',
          resource: 'tasks',
        ),
      );
    }
    final unresolvedSupport = data.support
        .where((row) => !{'resolved', 'closed'}.contains(row['status']))
        .length;
    if (unresolvedSupport > 0) {
      alerts.add(
        _ActionSignal(
          severity: _Severity.warning,
          icon: Icons.support_agent_outlined,
          title: 'حالات دعم لم تغلق',
          detail: '$unresolvedSupport حالة قيد المتابعة.',
          resource: 'support',
        ),
      );
    }
    if (receivables > 0) {
      alerts.add(
        _ActionSignal(
          severity: _Severity.info,
          icon: Icons.payments_outlined,
          title: 'ذمم عملاء قائمة',
          detail: '${receivables.toStringAsFixed(0)} ر.س وفق المؤشر المشتق.',
          resource: 'finance',
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        const _ActionSignal(
          severity: _Severity.ok,
          icon: Icons.check_circle_outline,
          title: 'لا توجد تنبيهات حرجة مشتقة حاليًا',
          detail: 'المؤشرات الحالية لا تعرض عنصرًا يتطلب تصعيدًا.',
          resource: 'dashboard',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _roleBanner(),
        const SizedBox(height: 16),
        Text(
          'الإجراءات ذات الأولوية',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...alerts.map(_actionTile),
      ],
    );
  }

  Widget _actionTile(_ActionSignal signal) {
    final color = switch (signal.severity) {
      _Severity.urgent => ManasaknaDesign.danger,
      _Severity.warning => ManasaknaDesign.warning,
      _Severity.info => ManasaknaDesign.brand,
      _Severity.ok => ManasaknaDesign.success,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          leading: Icon(signal.icon, color: color),
          title: Text(signal.title),
          subtitle: Text(signal.detail),
          trailing: signal.resource == 'dashboard'
              ? null
              : const Icon(Icons.arrow_back),
          onTap: signal.resource == 'dashboard'
              ? null
              : () => Navigator.pop(context, signal.resource),
        ),
      ),
    );
  }

  Widget _intelligence(_InsightsEnvelope data) {
    final activeBookings = data.bookings
        .where((row) => row['workflow_stage']?.toString() != 'closed')
        .length;
    final upcoming =
        (data.dashboard['upcoming_departures'] as num?)?.toInt() ??
        data.departures.length;
    final openQuotes = (data.dashboard['open_quotes'] as num?)?.toInt() ?? 0;
    final activeLeads = (data.dashboard['active_leads'] as num?)?.toInt() ?? 0;

    final observations = <String>[
      if (activeLeads > 0 && openQuotes == 0)
        'هناك فرص نشطة دون عروض مفتوحة؛ راجع مسار المبيعات.',
      if (activeBookings > 0 &&
          ((data.dashboard['missing_passports'] as num?)?.toInt() ?? 0) > 0)
        'الحجوزات النشطة تتضمن نواقص وثائق؛ الأولوية لرفع الجاهزية قبل المغادرة.',
      if (upcoming > 0)
        'هناك $upcoming مغادرة قادمة؛ راجع الجاهزية التشغيلية لكل مغادرة.',
      if (((data.dashboard['customer_receivables'] as num?) ?? 0) > 0)
        'توجد ذمم عملاء قائمة؛ يوصى بمراجعة الاستحقاقات قبل نقاط الانتقال الحرجة.',
    ];
    if (observations.isEmpty) {
      observations.add(
        'لا تظهر المؤشرات الحالية تعارضًا تشغيليًا واضحًا. استمر بالمراجعة الدورية.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _roleBanner(),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: ManasaknaDesign.brand),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ذكاء تشغيلي محكوم',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'هذه الاستنتاجات مشتقة حتميًا من سجلات النظام الحالية. '
                        'لم يتم تفعيل مزود ذكاء اصطناعي خارجي، ولا تنفذ هذه الصفحة أي تعديل حساس.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metric('فرص نشطة', activeLeads, Icons.person_search_outlined),
            _metric('عروض مفتوحة', openQuotes, Icons.request_quote_outlined),
            _metric(
              'حجوزات نشطة',
              activeBookings,
              Icons.confirmation_number_outlined,
            ),
            _metric('مغادرات قادمة', upcoming, Icons.flight_takeoff_outlined),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'قراءة تشغيلية',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...observations.map(
          (text) => Card(
            child: ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: Text(text),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roleBanner() => Card(
    child: ListTile(
      leading: const Icon(Icons.admin_panel_settings_outlined),
      title: Text('الدور الحالي: ${_roleLabel(widget.roleName)}'),
      subtitle: const Text(
        'تتحدد البيانات والإجراءات الفعلية بصلاحيات الخادم، وليس بإخفاء عناصر الواجهة.',
      ),
    ),
  );

  Widget _metric(String label, int value, IconData icon) => SizedBox(
    width: 220,
    child: Card(
      child: ListTile(
        leading: Icon(icon, color: ManasaknaDesign.brand),
        title: Text(
          '$value',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(label),
      ),
    ),
  );

  String _roleLabel(String role) => switch (role) {
    'owner' => 'مالك',
    'admin' => 'مسؤول',
    'manager' => 'مدير',
    'operator' => 'موظف عمليات',
    'viewer' => 'مشاهد',
    _ => role,
  };
}

enum _Severity { urgent, warning, info, ok }

class _ActionSignal {
  const _ActionSignal({
    required this.severity,
    required this.icon,
    required this.title,
    required this.detail,
    required this.resource,
  });
  final _Severity severity;
  final IconData icon;
  final String title;
  final String detail;
  final String resource;
}

class _InsightsEnvelope {
  const _InsightsEnvelope({
    required this.dashboard,
    required this.tasks,
    required this.support,
    required this.bookings,
    required this.travelers,
    required this.departures,
  });
  final Map<String, dynamic> dashboard;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> support;
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> travelers;
  final List<Map<String, dynamic>> departures;
}
