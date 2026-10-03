import 'package:flutter/material.dart';

import '../data/business_product_repository.dart';
import 'business_admin_page.dart';
import 'business_360_pages.dart';

enum BusinessWorkspace {
  dashboard,
  crm,
  leads,
  quotes,
  bookings,
  travelers,
  programs,
  documents,
  accommodation,
  transport,
  finance,
  suppliers,
  groups,
  tasks,
  support,
  reports,
}

class BusinessProductShell extends StatefulWidget {
  const BusinessProductShell({
    super.key,
    this.tenantId,
    this.tenantName = 'شركة العمرة التجريبية',
    this.repository,
    this.nonProduction = true,
    this.onSignOut,
  });
  final String? tenantId;
  final String tenantName;
  final BusinessProductRepository? repository;
  final bool nonProduction;
  final VoidCallback? onSignOut;
  @override
  State<BusinessProductShell> createState() => _BusinessProductShellState();
}

class _BusinessProductShellState extends State<BusinessProductShell> {
  BusinessWorkspace selected = BusinessWorkspace.dashboard;
  String query = '';
  final Map<String, Future<List<Map<String, dynamic>>>> _liveRequests = {};
  Future<Map<String, dynamic>>? _dashboardRequest;

  bool get _live => widget.repository != null && widget.tenantId != null;
  Future<List<Map<String, dynamic>>> _load(String resource) =>
      _liveRequests.putIfAbsent(
        resource,
        () => widget.repository!.list(widget.tenantId!, resource),
      );
  Future<Map<String, dynamic>> _loadDashboard() =>
      _dashboardRequest ??= widget.repository!.dashboard(widget.tenantId!);
  void _invalidate([String? resource]) {
    if (resource == null) {
      _liveRequests.clear();
    } else {
      _liveRequests.remove(resource);
    }
    _dashboardRequest = null;
    if (mounted) setState(() {});
  }

  final leads = <R>[
    R('LD-2401', 'محمد أحمد الخطيب', '0599001122', 'جديد', 'اليوم 10:30'),
    R('LD-2402', 'سارة محمود', '0568112233', 'تواصل', 'أمس 16:10'),
    R('LD-2403', 'عائلة أبو عمر', '0597445566', 'عرض مرسل', '29 أيلول'),
  ];
  final quotes = <R>[
    R(
      'QT-26031',
      'محمد أحمد الخطيب',
      'عمرة ربيع الآخر — 10 أيام',
      'مسودة',
      '4,850 ر.س',
    ),
    R(
      'QT-26030',
      'عائلة أبو عمر',
      'عمرة اقتصادية — 8 أيام',
      'مرسل',
      '18,900 ر.س',
    ),
  ];
  final bookings = <R>[
    R(
      'UMR-260124',
      'عائلة أبو عمر',
      'عمرة اقتصادية — 8 أيام',
      'مؤكد',
      '15 تشرين الأول',
    ),
    R(
      'UMR-260125',
      'ليان يوسف',
      'عمرة ربيع الآخر — 10 أيام',
      'وثائق',
      '22 تشرين الأول',
    ),
  ];
  final travelers = <R>[
    R('TR-771', 'عمر أبو عمر', 'P1234567', 'جاهز', 'UMR-260124'),
    R('TR-772', 'مريم أبو عمر', 'P7654321', 'نقص صورة', 'UMR-260124'),
    R('TR-773', 'ليان يوسف', 'P9988776', 'تأشيرة قيد المتابعة', 'UMR-260125'),
  ];
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.mosque_outlined),
            const SizedBox(width: 10),
            Text(wide ? 'مناسكنا للأعمال' : 'مناسكنا'),
            if (wide) ...[
              const SizedBox(width: 16),
              Text(
                widget.tenantName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
        actions: [
          if (widget.nonProduction && wide)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Chip(label: Text('بيئة اختبار — بيانات غير حقيقية')),
            ),
          if (_live)
            IconButton(
              tooltip: 'إدارة مساحة العمل',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BusinessAdminPage(
                    repository: widget.repository!,
                    tenantId: widget.tenantId!,
                    tenantName: widget.tenantName,
                  ),
                ),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          IconButton(
            tooltip: 'البحث السريع',
            onPressed: () => showSearch<void>(
              context: context,
              delegate: SearchAll([
                ...leads,
                ...quotes,
                ...bookings,
                ...travelers,
              ]),
            ),
            icon: const Icon(Icons.search),
          ),
          if (widget.onSignOut != null)
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      drawer: wide ? null : Drawer(child: SafeArea(child: nav())),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 245,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: SafeArea(child: nav()),
              ),
            ),
          Expanded(
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              child: workspace(),
            ),
          ),
        ],
      ),
    );
  }

  Widget nav() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.tenantName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text('مساحة عمليات العمرة', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: BusinessWorkspace.values
              .map(
                (w) => ListTile(
                  dense: true,
                  selected: selected == w,
                  leading: Icon(icon(w)),
                  title: Text(label(w)),
                  onTap: () {
                    setState(() => selected = w);
                    if (MediaQuery.sizeOf(context).width < 900) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
  Widget workspace() => SingleChildScrollView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 520 ? 12 : 24),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1400),
      child: _live
          ? liveWorkspace()
          : switch (selected) {
              BusinessWorkspace.dashboard => dashboard(),
              BusinessWorkspace.crm => table(
                'CRM والعملاء المحتملون',
                'عميل محتمل جديد',
                leads,
                ['الرقم', 'العميل', 'الهاتف', 'الحالة', 'آخر متابعة'],
              ),
              BusinessWorkspace.leads => table(
                'العملاء المحتملون',
                'فرصة جديدة',
                leads,
                ['الرقم', 'العميل', 'الهاتف', 'الحالة', 'آخر متابعة'],
              ),
              BusinessWorkspace.quotes => table('العروض', 'عرض جديد', quotes, [
                'رقم العرض',
                'العميل',
                'البرنامج',
                'الحالة',
                'القيمة',
              ]),
              BusinessWorkspace.bookings => table(
                'الحجوزات',
                'حجز جديد',
                bookings,
                ['رقم الحجز', 'العميل', 'البرنامج', 'الحالة', 'المغادرة'],
              ),
              BusinessWorkspace.travelers => table(
                'المسافرون',
                'مسافر جديد',
                travelers,
                ['الرقم', 'المسافر', 'الجواز', 'الجاهزية', 'الحجز'],
              ),
              BusinessWorkspace.programs => cards('البرامج والمغادرات', [
                (
                  'عمرة اقتصادية — 8 أيام',
                  '15–23 تشرين الأول',
                  '18/24 مقعدًا • مكة 4 • المدينة 3',
                ),
                (
                  'عمرة ربيع الآخر — 10 أيام',
                  '22–31 تشرين الأول',
                  '12/30 مقعدًا • مكة 5 • المدينة 4',
                ),
              ], action: 'برنامج جديد'),
              BusinessWorkspace.documents => cards('الوثائق والتأشيرات', [
                ('UMR-260124 — عمر أبو عمر', 'الجواز مكتمل', 'جاهز'),
                (
                  'UMR-260124 — مريم أبو عمر',
                  'صورة الجواز ناقصة',
                  'يتطلب إجراء',
                ),
                (
                  'UMR-260125 — ليان يوسف',
                  'ملف التأشيرة مكتمل',
                  'قيد المتابعة',
                ),
              ]),
              BusinessWorkspace.accommodation => cards('الإقامة والغرف', [
                (
                  'UMR-260124',
                  'مكة: دار الضيافة — غرفة 402',
                  'المدينة: الهدى — غرفة 218',
                ),
                ('UMR-260125', 'مكة: قيد التخصيص', 'المدينة: قيد التخصيص'),
              ]),
              BusinessWorkspace.transport => cards('الطيران والنقل', [
                (
                  'UMR-260124',
                  'AMM → JED • 15 تشرين الأول 08:20',
                  'نقل مطار → مكة مؤكد',
                ),
                (
                  'UMR-260125',
                  'مقطع جوي غير مربوط',
                  'النقل الأرضي بانتظار البرنامج',
                ),
              ]),
              BusinessWorkspace.finance => finance(),
              BusinessWorkspace.suppliers => cards('الموردون', [
                ('فندق دار الضيافة', 'إقامة', 'رصيد مستحق 12,400 ر.س'),
                ('نقل الحرمين', 'نقل', '3 خدمات قادمة'),
                ('مورد تذاكر الاختبار', 'طيران', '2 ملف متابعة'),
              ]),
              BusinessWorkspace.groups => cards('المجموعات والمشرفون', [
                ('مجموعة UMR-260124', '18 مسافرًا', 'المشرف: أحمد سالم'),
                ('مجموعة UMR-260125', '12 مسافرًا', 'المشرف: قيد التعيين'),
              ]),
              BusinessWorkspace.tasks => cards('المهام التشغيلية', [
                ('استكمال ملف الحجز', 'UMR-260124', 'مفتوح'),
                ('مراجعة المغادرة', 'UMR-260125', 'قيد التنفيذ'),
              ]),
              BusinessWorkspace.support => cards('الدعم التشغيلي', [
                ('SUP-118', 'تعديل اسم مسافر', 'مفتوح — أولوية متوسطة'),
                ('SUP-117', 'استفسار عن السكن', 'بانتظار العميل'),
              ]),
              BusinessWorkspace.reports => cards('التقارير', [
                (
                  'قمع المبيعات',
                  'Leads → عروض → حجوزات',
                  'نسبة التحويل التجريبية 66%',
                ),
                (
                  'جاهزية المغادرات',
                  'الوثائق والتأشيرات والسكن والنقل',
                  'مغادرة واحدة تتطلب إجراء',
                ),
                ('التحصيلات', 'المدفوع والمتبقي', '6,250 ر.س متبقي'),
                (
                  'ربحية البرامج',
                  'الإيراد مقابل التكلفة التشغيلية',
                  'بيانات اختبار فقط',
                ),
              ]),
            },
    ),
  );
  Widget liveWorkspace() => switch (selected) {
    BusinessWorkspace.dashboard => liveDashboard(),
    BusinessWorkspace.crm => liveResource(
      'customers',
      'CRM والعملاء',
      createKind: 'customer',
    ),
    BusinessWorkspace.leads => liveResource(
      'leads',
      'العملاء المحتملون',
      createKind: 'lead',
    ),
    BusinessWorkspace.quotes => liveResource(
      'quotes',
      'العروض',
      createKind: 'quote',
    ),
    BusinessWorkspace.bookings => liveResource(
      'bookings',
      'الحجوزات',
      createKind: 'booking',
    ),
    BusinessWorkspace.travelers => liveResource(
      'travelers',
      'المسافرون',
      createKind: 'traveler',
    ),
    BusinessWorkspace.programs => liveResourceGroup(
      'البرامج والمغادرات',
      const [
        ('packages', 'البرامج', 'package'),
        ('departures', 'المغادرات', 'departure'),
      ],
    ),
    BusinessWorkspace.documents => liveResourceGroup(
      'الوثائق والتأشيرات',
      const [
        ('documents', 'وثائق المسافرين', 'document'),
        ('visas', 'ملفات التأشيرات', 'visa'),
      ],
    ),
    BusinessWorkspace.accommodation => liveResourceGroup(
      'الإقامة والغرف',
      const [
        ('properties', 'الفنادق / مرافق الإقامة', 'property'),
        ('accommodation', 'توزيع الغرف', 'accommodation'),
      ],
    ),
    BusinessWorkspace.transport => liveResourceGroup(
      'الطيران والنقل',
      const [
        ('flights', 'مقاطع الطيران', 'flight'),
        ('transport', 'النقل الأرضي', 'transport'),
      ],
    ),
    BusinessWorkspace.finance => liveResource(
      'finance',
      'المالية التشغيلية',
      createKind: 'finance',
    ),
    BusinessWorkspace.suppliers => liveResource(
      'suppliers',
      'الموردون',
      createKind: 'supplier',
    ),
    BusinessWorkspace.groups => liveResourceGroup(
      'المجموعات والمشرفون',
      const [
        ('groups', 'المجموعات', 'group'),
        ('supervisors', 'المشرفون', 'supervisor'),
      ],
    ),
    BusinessWorkspace.tasks => liveResource(
      'tasks',
      'المهام التشغيلية',
      createKind: 'task',
    ),
    BusinessWorkspace.support => liveResource(
      'support',
      'الدعم التشغيلي',
      createKind: 'support',
    ),
    BusinessWorkspace.reports => liveDashboard(reports: true),
  };

  Widget liveDashboard({bool reports = false}) =>
      FutureBuilder<Map<String, dynamic>>(
        future: _loadDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            );
          }
          if (snapshot.hasError) return liveError(snapshot.error);
          final data = snapshot.data ?? const <String, dynamic>{};
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header(
                reports ? 'التقارير والمؤشرات' : 'صباح الخير — عمليات اليوم',
                'بيانات مشتقة مباشرة من مساحة المكتب الحالية.',
                action: IconButton(
                  onPressed: _invalidate,
                  tooltip: 'تحديث',
                  icon: const Icon(Icons.refresh),
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: data.entries
                    .where(
                      (e) =>
                          e.value is num ||
                          e.value is String ||
                          e.value is bool,
                    )
                    .take(12)
                    .map(
                      (e) => metric(
                        _fieldLabel(e.key),
                        _display(e.value),
                        Icons.insights_outlined,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              _dashboardCommandCenter(data),
              if (data.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('لا توجد مؤشرات مشتقة متاحة لهذه العضوية.'),
                ),
            ],
          );
        },
      );

  Widget _dashboardCommandCenter(Map<String, dynamic> data) {
    final missing = (data['missing_passports'] as num?)?.toInt() ?? 0;
    final openTasks = (data['open_tasks'] as num?)?.toInt() ?? 0;
    final receivables = (data['customer_receivables'] as num?) ?? 0;
    final upcoming = (data['upcoming_departures'] as num?)?.toInt() ?? 0;
    void go(BusinessWorkspace workspace) => setState(() => selected = workspace);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مركز الإجراءات',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionCard(
              Icons.badge_outlined,
              'وثائق تحتاج متابعة',
              missing == 0 ? 'لا توجد نواقص مسجلة' : '$missing مسافر/وثيقة تحتاج إجراء',
              missing == 0 ? Colors.green : Colors.orange,
              () => go(BusinessWorkspace.documents),
            ),
            _actionCard(
              Icons.task_alt_outlined,
              'المهام المفتوحة',
              '$openTasks مهمة تحتاج متابعة',
              openTasks == 0 ? Colors.green : Colors.orange,
              () => go(BusinessWorkspace.tasks),
            ),
            _actionCard(
              Icons.payments_outlined,
              'التحصيلات',
              '${receivables.toStringAsFixed(0)} ر.س ذمم قائمة',
              receivables <= 0 ? Colors.green : Colors.orange,
              () => go(BusinessWorkspace.finance),
            ),
            _actionCard(
              Icons.flight_takeoff_outlined,
              'المغادرات القادمة',
              '$upcoming مغادرة تحت المتابعة',
              Colors.blue,
              () => go(BusinessWorkspace.programs),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'إجراءات سريعة',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => go(BusinessWorkspace.crm),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('عميل جديد'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => go(BusinessWorkspace.leads),
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('متابعة فرصة'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => go(BusinessWorkspace.quotes),
              icon: const Icon(Icons.request_quote_outlined),
              label: const Text('إنشاء عرض'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => go(BusinessWorkspace.bookings),
              icon: const Icon(Icons.confirmation_number_outlined),
              label: const Text('فتح الحجوزات'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionCard(
    IconData icon,
    String title,
    String detail,
    Color accent,
    VoidCallback onTap,
  ) =>
      SizedBox(
        width: 260,
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: accent),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(detail),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('فتح'),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_back, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget liveResourceGroup(
    String title,
    List<(String, String, String)> panes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          title,
          'مساحات تشغيل مترابطة، لكل مورد سجل ونموذج وحالة مستقلة.',
        ),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'بحث في هذه المساحة',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ...panes.map((pane) {
          final resource = pane.$1;
          final paneTitle = pane.$2;
          final createKind = pane.$3;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _load(resource),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: LinearProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) return liveError(snapshot.error);
                final rows = snapshot.data ?? const <Map<String, dynamic>>[];
                final filtered = rows.where((row) {
                  if (query.trim().isEmpty) return true;
                  final q = query.toLowerCase();
                  return row.values.any(
                    (v) => _display(v).toLowerCase().contains(q),
                  );
                }).toList();
                return Card(
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(
                      paneTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('${filtered.length} سجل'),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => liveCreateDialog(createKind, resource),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة'),
                    ),
                    children: [
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text('لا توجد سجلات في هذه المساحة.'),
                          ),
                        )
                      else
                        ...filtered.map(
                          (row) => ListTile(
                            leading: const Icon(Icons.chevron_left),
                            title: Text(_primary(row)),
                            subtitle: Text(
                              _secondary(row),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: row['status'] == null
                                ? null
                                : Chip(label: Text(_display(row['status']))),
                            onTap: () => liveDetails(resource, row),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget liveResource(
    String resource,
    String title, {
    String? createKind,
    String? secondaryCreateKind,
  }) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _load(resource),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (snapshot.hasError) return liveError(snapshot.error);
      final rows = snapshot.data ?? const <Map<String, dynamic>>[];
      final filtered = rows.where((row) {
        if (query.trim().isEmpty) return true;
        final q = query.toLowerCase();
        return row.values.any((v) => _display(v).toLowerCase().contains(q));
      }).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(
            title,
            'قراءة حية محكومة بالصلاحيات من مستودع Phase 13.',
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _invalidate(resource),
                  tooltip: 'تحديث',
                  icon: const Icon(Icons.refresh),
                ),
                if (secondaryCreateKind != null)
                  TextButton.icon(
                    onPressed: () =>
                        liveCreateDialog(secondaryCreateKind, resource),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: Text(_createLabel(secondaryCreateKind)),
                  ),
                if (createKind != null)
                  FilledButton.icon(
                    onPressed: () => liveCreateDialog(createKind, resource),
                    icon: const Icon(Icons.add),
                    label: Text(_createLabel(createKind)),
                  ),
              ],
            ),
          ),
          TextField(
            onChanged: (v) => setState(() => query = v),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'بحث في السجلات الحالية',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('لا توجد سجلات مطابقة.'),
              ),
            )
          else
            ...filtered.map(
              (row) => Card(
                child: ListTile(
                  leading: const Icon(Icons.chevron_left),
                  title: Text(_primary(row)),
                  subtitle: Text(
                    _secondary(row),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: row['status'] == null
                      ? null
                      : Chip(label: Text(_display(row['status']))),
                  onTap: () => liveDetails(resource, row),
                ),
              ),
            ),
        ],
      );
    },
  );

  Widget liveError(Object? error) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تعذر تحميل البيانات ضمن الصلاحية الحالية.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(error?.toString() ?? 'UNKNOWN_ERROR'),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: _invalidate,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    ),
  );

  String _primary(Map<String, dynamic> row) {
    for (final key in const [
      'full_name',
      'name',
      'summary',
      'booking_code',
      'quote_code',
      'customer_code',
      'traveler_code',
      'case_code',
      'reference',
      'id',
    ]) {
      final value = row[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return 'سجل';
  }

  String _secondary(Map<String, dynamic> row) {
    const ignored = {
      'id',
      'tenant_id',
      'created_by',
      'updated_by',
      'correlation_id',
    };
    return row.entries
        .where(
          (e) =>
              !ignored.contains(e.key) &&
              e.value != null &&
              e.value.toString().isNotEmpty,
        )
        .take(4)
        .map((e) => '${_fieldLabel(e.key)}: ${_display(e.value)}')
        .join(' • ');
  }

  String _display(Object? value) {
    if (value == null) return '—';
    if (value is List) return value.map(_display).join('، ');
    if (value is Map) {
      return value.entries
          .map((e) => '${e.key}: ${_display(e.value)}')
          .join('، ');
    }
    return value.toString();
  }

  String _fieldLabel(String key) => switch (key) {
    'active_leads' => 'فرص نشطة',
    'open_quotes' => 'عروض مفتوحة',
    'active_bookings' => 'حجوزات نشطة',
    'upcoming_departures' => 'مغادرات قادمة',
    'missing_passports' => 'جوازات ناقصة',
    'open_tasks' => 'مهام مفتوحة',
    'open_support' => 'حالات دعم مفتوحة',
    'customer_receivables' => 'ذمم العملاء',
    'supplier_payables' => 'مستحقات الموردين',
    'travelers' => 'المسافرون',
    'documents_ready' => 'الوثائق جاهزة',
    'visas_ready' => 'التأشيرات جاهزة',
    'accommodation_ready' => 'الإقامة جاهزة',
    'air_ready' => 'الطيران جاهز',
    'transport_ready' => 'النقل جاهز',
    'total_amount' => 'إجمالي الحجز',
    'paid_amount' => 'المدفوع',
    'outstanding_amount' => 'المتبقي',
    'financially_ready' => 'الجاهزية المالية',
    _ => key.replaceAll('_', ' '),
  };

  String _createLabel(String kind) => switch (kind) {
    'customer' => 'عميل جديد',
    'lead' => 'فرصة جديدة',
    'quote' => 'عرض جديد',
    'booking' => 'حجز جديد',
    'traveler' => 'مسافر جديد',
    'task' => 'مهمة جديدة',
    'support' => 'حالة دعم',
    'finance' => 'حركة مالية',
    _ => 'إضافة',
  };

  String? _relationResource(String field) => switch (field) {
    'customer_id' => 'customers',
    'lead_id' => 'leads',
    'quote_id' => 'quotes',
    'booking_id' => 'bookings',
    'departure_id' => 'departures',
    'package_id' => 'packages',
    'traveler_id' => 'travelers',
    'supplier_id' => 'suppliers',
    'property_id' => 'properties',
    'group_id' => 'groups',
    'supervisor_id' => 'supervisors',
    _ => null,
  };

  Widget _formEditor(
    (String, String, bool) field,
    TextEditingController controller,
    Map<String, List<Map<String, dynamic>>> relationRows,
    bool busy,
  ) {
    final resource = _relationResource(field.$1);
    if (resource != null) {
      final options = relationRows[field.$1] ?? const <Map<String, dynamic>>[];
      return DropdownButtonFormField<String>(
        initialValue: controller.text.isEmpty ? null : controller.text,
        isExpanded: true,
        items: options
            .map(
              (row) => DropdownMenuItem<String>(
                value: row['id']?.toString(),
                child: Text(_primary(row), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: busy ? null : (value) => controller.text = value ?? '',
        decoration: InputDecoration(
          labelText: field.$2,
          helperText: field.$3 ? 'مطلوب' : null,
          border: const OutlineInputBorder(),
        ),
      );
    }
    return TextField(
      controller: controller,
      enabled: !busy,
      decoration: InputDecoration(
        labelText: field.$2,
        helperText: field.$3 ? 'مطلوب' : null,
        border: const OutlineInputBorder(),
      ),
    );
  }

  List<(String, String, bool)> _formFields(String kind) => switch (kind) {
    'customer' => const [
      ('full_name', 'الاسم الكامل', true),
      ('full_name_en', 'الاسم بالإنجليزية', false),
      ('phone', 'الهاتف', false),
      ('whatsapp', 'واتساب', false),
      ('email', 'البريد الإلكتروني', false),
      ('customer_type', 'نوع العميل', false),
      ('nationality', 'الجنسية', false),
      ('country_of_residence', 'بلد الإقامة', false),
      ('city', 'المدينة', false),
      ('preferred_locale', 'اللغة المفضلة', false),
      ('source_channel', 'قناة المصدر', false),
      ('tags', 'وسوم مفصولة بفواصل', false),
      ('communication_consent', 'موافقة التواصل true/false', false),
    ],
    'lead' => const [
      ('customer_id', 'العميل', true),
      ('source', 'المصدر', false),
      ('notes', 'ملاحظات', false),
      ('expected_travelers', 'عدد المسافرين المتوقع', false),
      ('budget_min', 'الميزانية الدنيا', false),
      ('budget_max', 'الميزانية العليا', false),
      ('budget_currency', 'عملة الميزانية', false),
      ('next_follow_up_at', 'المتابعة القادمة ISO-8601', false),
    ],
    'quote' => const [
      ('lead_id', 'الفرصة', true),
      ('quote_code', 'رقم العرض', false),
      ('currency', 'العملة', true),
      ('subtotal_amount', 'المجموع قبل الخصم والضريبة', true),
      ('discount_amount', 'الخصم', false),
      ('tax_amount', 'الضريبة', false),
      ('fee_amount', 'الرسوم', false),
      ('valid_until', 'صالح حتى YYYY-MM-DD', false),
      ('payment_terms', 'شروط الدفع', false),
      ('cancellation_terms', 'شروط الإلغاء', false),
      ('departure_id', 'المغادرة', false),
    ],
    'booking' => const [
      ('quote_id', 'عرض السعر المقبول', true),
      ('booking_code', 'رقم الحجز', false),
      ('departure_id', 'المغادرة', false),
      ('total_amount', 'إجمالي الحجز', false),
      ('currency', 'العملة', false),
      ('payment_condition', 'شرط الدفع', false),
      ('external_reference', 'مرجع خارجي', false),
    ],
    'traveler' => const [
      ('booking_id', 'الحجز', true),
      ('full_name', 'اسم المسافر', true),
      ('passport_reference', 'مرجع الجواز', true),
      ('nationality', 'الجنسية', false),
      ('date_of_birth', 'تاريخ الميلاد YYYY-MM-DD', false),
      ('passport_expires_on', 'انتهاء الجواز YYYY-MM-DD', false),
      ('phone', 'الهاتف', false),
    ],
    'task' => const [
      ('booking_id', 'الحجز', true),
      ('title', 'عنوان المهمة', true),
      ('task_type', 'نوع المهمة', false),
      ('priority', 'الأولوية', false),
      ('due_at', 'موعد الاستحقاق ISO-8601', false),
    ],
    'support' => const [
      ('booking_id', 'الحجز', true),
      ('category', 'التصنيف', true),
      ('summary', 'ملخص الحالة', true),
      ('priority', 'الأولوية', false),
    ],
    'finance' => const [
      ('booking_id', 'الحجز', true),
      ('entry_type', 'نوع الحركة', true),
      ('amount', 'المبلغ', true),
      ('currency', 'العملة', true),
      ('reference', 'المرجع', false),
      ('payment_method', 'طريقة الدفع', false),
      ('receipt_number', 'رقم السند', false),
      ('notes', 'ملاحظات', false),
    ],
    'package' => const [
      ('name', 'اسم البرنامج', true),
      ('duration_days', 'المدة بالأيام', true),
      ('description', 'وصف البرنامج', false),
      ('base_price', 'السعر الأساسي', false),
      ('currency', 'العملة', false),
      ('status', 'الحالة', false),
    ],
    'departure' => const [
      ('package_id', 'البرنامج', true),
      ('start_date', 'تاريخ المغادرة YYYY-MM-DD', true),
      ('end_date', 'تاريخ العودة YYYY-MM-DD', true),
      ('capacity', 'السعة', true),
      ('status', 'الحالة', false),
    ],
    'document' => const [
      ('traveler_id', 'المسافر', true),
      ('document_type', 'نوع الوثيقة', true),
      ('document_reference', 'مرجع الوثيقة', true),
      ('document_number', 'رقم الوثيقة', false),
      ('issued_on', 'تاريخ الإصدار YYYY-MM-DD', false),
      ('expires_on', 'تاريخ الانتهاء YYYY-MM-DD', false),
      ('issuing_country', 'بلد الإصدار', false),
      ('verification_status', 'حالة المراجعة', false),
      ('rejection_reason', 'سبب الرفض', false),
    ],
    'visa' => const [
      ('traveler_id', 'المسافر', true),
      ('status', 'حالة التأشيرة', true),
      ('visa_type', 'نوع التأشيرة', false),
      ('application_reference', 'مرجع الطلب', false),
      ('authority_source', 'مصدر الحالة', false),
      ('external_reference', 'المرجع الخارجي', false),
      ('expires_on', 'تاريخ الانتهاء YYYY-MM-DD', false),
      ('rejection_reason', 'سبب الرفض', false),
    ],
    'property' => const [
      ('supplier_id', 'مورد الفندق', false),
      ('name', 'اسم الفندق / المنشأة', true),
      ('city', 'المدينة', true),
      ('address', 'العنوان', false),
      ('star_rating', 'التصنيف النجمي', false),
      ('distance_to_haram_m', 'المسافة إلى الحرم بالمتر', false),
      ('contact_phone', 'هاتف المنشأة', false),
      ('status', 'الحالة', false),
    ],
    'accommodation' => const [
      ('booking_id', 'الحجز', true),
      ('property_id', 'الفندق / المنشأة', true),
      ('traveler_id', 'المسافر', false),
      ('room_label', 'رقم / رمز الغرفة', true),
      ('check_in', 'تاريخ الدخول YYYY-MM-DD', true),
      ('check_out', 'تاريخ الخروج YYYY-MM-DD', true),
      ('room_type', 'نوع الغرفة', false),
      ('occupancy', 'الإشغال', false),
      ('status', 'الحالة', false),
      ('notes', 'ملاحظات', false),
    ],
    'flight' => const [
      ('booking_id', 'الحجز', true),
      ('flight_number', 'رقم الرحلة', true),
      ('origin', 'مطار المغادرة', true),
      ('destination', 'مطار الوصول', true),
      ('departure_at', 'موعد المغادرة ISO-8601', true),
      ('arrival_at', 'موعد الوصول ISO-8601', true),
      ('provider_name', 'شركة الطيران', false),
      ('segment_type', 'نوع المقطع', false),
      ('airline_code', 'رمز الناقل', false),
      ('booking_reference', 'PNR / مرجع الحجز', false),
      ('ticket_status', 'حالة التذكرة', false),
      ('cabin_class', 'درجة السفر', false),
      ('baggage_allowance', 'الأمتعة', false),
      ('status', 'حالة الرحلة', false),
    ],
    'transport' => const [
      ('booking_id', 'الحجز', true),
      ('supplier_id', 'المورد', false),
      ('mode', 'وسيلة النقل', true),
      ('operator_name', 'اسم المشغل', false),
      ('pickup', 'نقطة الالتقاط', true),
      ('dropoff', 'نقطة الوصول', true),
      ('scheduled_at', 'الموعد ISO-8601', true),
      ('vehicle_reference', 'مرجع المركبة', false),
      ('driver_name', 'اسم السائق', false),
      ('driver_phone', 'هاتف السائق', false),
      ('capacity', 'السعة', false),
      ('status', 'الحالة', false),
    ],
    'supplier' => const [
      ('name', 'اسم المورد', true),
      ('supplier_type', 'نوع المورد', true),
      ('contact_name', 'جهة الاتصال', false),
      ('phone', 'الهاتف', false),
      ('email', 'البريد الإلكتروني', false),
      ('country', 'الدولة', false),
      ('city', 'المدينة', false),
      ('payment_terms', 'شروط الدفع', false),
      ('notes', 'ملاحظات', false),
      ('status', 'الحالة', false),
    ],
    'group' => const [
      ('departure_id', 'المغادرة', true),
      ('code', 'رمز المجموعة', true),
      ('name', 'اسم المجموعة', true),
      ('capacity', 'السعة', false),
      ('status', 'الحالة', false),
    ],
    'supervisor' => const [
      ('group_id', 'المجموعة', true),
      ('display_name', 'اسم المشرف', true),
      ('phone', 'الهاتف', false),
      ('email', 'البريد الإلكتروني', false),
      ('role_title', 'المسمى', false),
      ('status', 'الحالة', false),
    ],
    _ => const [],
  };

  Future<void> liveCreateDialog(String kind, String resource) async {
    final fields = _formFields(kind);
    final controllers = {for (final f in fields) f.$1: TextEditingController()};
    final relationRows = <String, List<Map<String, dynamic>>>{};
    for (final field in fields) {
      final relationResource = _relationResource(field.$1);
      if (relationResource != null) {
        relationRows[field.$1] = await widget.repository!.list(
          widget.tenantId!,
          relationResource,
          limit: 100,
        );
      }
    }
    if (kind == 'finance') controllers['currency']!.text = 'SAR';
    if (kind == 'customer') {
      controllers['customer_type']!.text = 'individual';
      controllers['preferred_locale']!.text = 'ar';
      controllers['source_channel']!.text = 'manual';
      controllers['communication_consent']!.text = 'false';
    }
    if (kind == 'lead') {
      controllers['source']!.text = 'manual';
    }
    if (kind == 'quote') {
      controllers['currency']!.text = 'SAR';
      controllers['discount_amount']!.text = '0';
      controllers['tax_amount']!.text = '0';
      controllers['fee_amount']!.text = '0';
    }
    if (kind == 'booking') {
      controllers['payment_condition']!.text = 'deposit_required';
    }
    if (kind == 'task' || kind == 'support') {
      controllers['priority']!.text = 'normal';
    }
    if (kind == 'package') {
      controllers['duration_days']!.text = '8';
      controllers['base_price']!.text = '0';
      controllers['currency']!.text = 'SAR';
      controllers['status']!.text = 'draft';
    }
    if (kind == 'departure') {
      controllers['capacity']!.text = '1';
      controllers['status']!.text = 'planned';
    }
    if (kind == 'document') {
      controllers['verification_status']!.text = 'pending';
    }
    if (kind == 'visa') {
      controllers['status']!.text = 'not_started';
      controllers['visa_type']!.text = 'umrah';
    }
    if (kind == 'property') controllers['status']!.text = 'active';
    if (kind == 'accommodation') {
      controllers['occupancy']!.text = '1';
      controllers['status']!.text = 'reserved';
    }
    if (kind == 'flight') {
      controllers['segment_type']!.text = 'outbound';
      controllers['ticket_status']!.text = 'planned';
      controllers['status']!.text = 'scheduled';
    }
    if (kind == 'transport') {
      controllers['mode']!.text = 'bus';
      controllers['status']!.text = 'planned';
    }
    if (kind == 'supplier') controllers['status']!.text = 'active';
    if (kind == 'group') controllers['status']!.text = 'forming';
    if (kind == 'supervisor') controllers['status']!.text = 'assigned';
    String? error;
    var busy = false;
    var saved = false;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('إضافة ${label(selected)}'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'بيانات اختبار فقط — لا يسمح ببيانات مستخدمين حقيقية.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...fields.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _formEditor(
                        f,
                        controllers[f.$1]!,
                        relationRows,
                        busy,
                      ),
                    ),
                  ),
                  if (error != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final values = {
                        for (final f in fields)
                          f.$1: controllers[f.$1]!.text.trim(),
                      };
                      final missing = fields
                          .where((f) => f.$3 && values[f.$1]!.isEmpty)
                          .toList();
                      if (missing.isNotEmpty) {
                        setDialogState(() => error = 'أكمل الحقول المطلوبة.');
                        return;
                      }
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await _saveLive(kind, values, resource);
                        saved = true;
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        setDialogState(() {
                          busy = false;
                          error = e.toString();
                        });
                      }
                    },
              child: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    // Dialog route disposal removes TextField listeners after its reverse animation.
    // Controllers are local-only and become unreachable with this method invocation.
    if (saved && mounted) {
      _invalidate(resource);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الحفظ في بيئة الاختبار وتحديث البيانات.'),
        ),
      );
    }
  }

  Future<void> _saveLive(
    String kind,
    Map<String, String> values,
    String resource,
  ) async {
    final repo = widget.repository!;
    final tenant = widget.tenantId!;
    final payload = <String, dynamic>{...values}
      ..removeWhere((key, value) => value is String && value.isEmpty)
      ..['data_classification'] = 'synthetic'
      ..['source_provenance'] = 'phase13_operator_console';
    final bookingId = payload.remove('booking_id')?.toString();
    final customerId = payload.remove('customer_id')?.toString();
    final leadId = payload.remove('lead_id')?.toString();
    final quoteId = payload.remove('quote_id')?.toString();
    if (kind == 'customer') {
      final rawTags = payload['tags']?.toString();
      payload['tags'] = rawTags == null
          ? <String>[]
          : rawTags
                .split(',')
                .map((x) => x.trim())
                .where((x) => x.isNotEmpty)
                .toList();
      payload['communication_consent'] =
          payload['communication_consent']?.toString().toLowerCase() == 'true';
      await repo.saveCustomer(tenant, payload: payload);
      return;
    }
    if (kind == 'lead') {
      await repo.saveLead(tenant, customerId!, payload: payload);
      return;
    }
    if (kind == 'quote') {
      await repo.saveQuote(tenant, leadId!, payload: payload);
      return;
    }
    if (kind == 'booking') {
      payload['idempotency_key'] =
          'ui-booking-${DateTime.now().microsecondsSinceEpoch}';
      await repo.saveBooking(tenant, quoteId!, payload: payload);
      return;
    }
    if (kind == 'traveler') {
      await repo.saveTraveler(tenant, bookingId!, payload: payload);
      return;
    }
    if (kind == 'task') {
      await repo.saveTask(tenant, bookingId!, payload: payload);
      return;
    }
    if (kind == 'support') {
      await repo.saveSupport(tenant, bookingId!, payload: payload);
      return;
    }
    if (kind == 'finance') {
      payload['idempotency_key'] =
          'ui-${DateTime.now().microsecondsSinceEpoch}';
      await repo.saveFinance(tenant, bookingId!, payload);
      return;
    }
    await repo.saveResource(tenant, resource, payload: payload);
  }

  String? _statusResource(String resource) => switch (resource) {
    'leads' => 'lead',
    'quotes' => 'quote',
    'tasks' => 'task',
    'support' => 'support',
    _ => null,
  };

  List<String> _statusTargets(String resource, String current) =>
      switch ((resource, current)) {
        ('leads', 'new') => const ['qualified', 'lost'],
        ('leads', 'qualified') => const ['quoted', 'lost'],
        ('leads', 'quoted') => const ['booked', 'lost'],
        ('quotes', 'draft') => const ['sent', 'rejected'],
        ('quotes', 'sent') => const ['accepted', 'rejected', 'expired'],
        ('tasks', 'open') => const ['in_progress', 'done', 'cancelled'],
        ('tasks', 'in_progress') => const ['done', 'cancelled'],
        ('support', 'open') => const ['pending', 'resolved'],
        ('support', 'pending') => const ['open', 'resolved'],
        ('support', 'resolved') => const ['closed'],
        _ => const [],
      };

  Future<bool> liveStatusDialog(
    String resource,
    Map<String, dynamic> row,
  ) async {
    final rpcResource = _statusResource(resource);
    final current = row['status']?.toString() ?? '';
    final targets = _statusTargets(resource, current);
    if (rpcResource == null || targets.isEmpty) return false;
    var target = targets.first;
    var reason = '';
    String? error;
    var busy = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تحديث الحالة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: target,
                decoration: const InputDecoration(
                  labelText: 'الحالة الجديدة',
                  border: OutlineInputBorder(),
                ),
                items: targets
                    .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                    .toList(),
                onChanged: busy ? null : (v) => target = v ?? target,
              ),
              const SizedBox(height: 12),
              TextField(
                enabled: !busy,
                onChanged: (v) => reason = v,
                decoration: const InputDecoration(
                  labelText: 'السبب / الملاحظة',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() {
                        busy = true;
                        error = null;
                      });
                      try {
                        await widget.repository!.updateStatus(
                          widget.tenantId!,
                          rpcResource,
                          row['id'].toString(),
                          target,
                          reason: reason.trim().isEmpty ? null : reason.trim(),
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (e) {
                        setDialogState(() {
                          busy = false;
                          error = e.toString();
                        });
                      }
                    },
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _invalidate(resource);
    return saved == true;
  }

  String? _nextBookingStage(String current) => switch (current) {
    'booking' => 'travelers',
    'travelers' => 'documents',
    'documents' => 'visa',
    'visa' => 'program',
    'program' => 'accommodation',
    'accommodation' => 'air',
    'air' => 'transport',
    'transport' => 'payments',
    'payments' => 'departure_readiness',
    'departure_readiness' => 'departed',
    'departed' => 'in_trip',
    'in_trip' => 'returned',
    'returned' => 'closed',
    _ => null,
  };

  Future<bool> _advanceBooking(Map<String, dynamic> row) async {
    final next = _nextBookingStage(row['workflow_stage']?.toString() ?? '');
    if (next == null) return false;
    try {
      await widget.repository!.advanceBooking(
        widget.tenantId!,
        row['id'].toString(),
        next,
        reason: 'phase13_operator_console',
        idempotencyKey:
            'ui-stage-${row['id']}-$next-${DateTime.now().microsecondsSinceEpoch}',
      );
      _invalidate('bookings');
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return false;
    }
  }

  Future<void> _open360(
    String resource,
    Map<String, dynamic> row,
  ) async {
    final entity = switch (resource) {
      'customers' => 'customer',
      'bookings' => 'booking',
      'departures' => 'departure',
      _ => null,
    };
    if (entity == null) return;
    final envelope = await widget.repository!.entity360(
      widget.tenantId!,
      entity,
      row['id'].toString(),
    );
    if (!mounted) return;
    final rawRecord = envelope['record'];
    final record = rawRecord is Map
        ? rawRecord.map((k, v) => MapEntry(k.toString(), v))
        : Map<String, dynamic>.from(row);
    final sections = <String, List<Map<String, dynamic>>>{};
    final rawSections = envelope['sections'];
    if (rawSections is Map) {
      for (final entry in rawSections.entries) {
        final value = entry.value;
        if (value is List) {
          sections[entry.key.toString()] = value
              .whereType<Map>()
              .map((x) => x.map((k, v) => MapEntry(k.toString(), v)))
              .toList(growable: false);
        }
      }
    }
    final rawReadiness = envelope['readiness'];
    final readiness = rawReadiness is Map
        ? rawReadiness.map((k, v) => MapEntry(k.toString(), v))
        : null;
    final page = switch (entity) {
      'customer' => Customer360Page(record: record, sections: sections),
      'booking' => Booking360Page(
          record: record,
          sections: sections,
          readiness: readiness,
        ),
      'departure' => Departure360Page(record: record, sections: sections),
      _ => Business360Page(
          title: 'ملف 360°',
          record: record,
          sections: sections,
        ),
    };
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void liveDetails(
    String resource,
    Map<String, dynamic> row,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .94,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          children: [
            Text(
              _primary(row),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (const {'customers', 'bookings', 'departures'}.contains(resource)) ...[
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    Navigator.pop(c);
                    await _open360(resource, row);
                  },
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  label: const Text('فتح ملف 360°'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_statusTargets(
              resource,
              row['status']?.toString() ?? '',
            ).isNotEmpty) ...[
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    final changed = await liveStatusDialog(resource, row);
                    if (changed && c.mounted) Navigator.pop(c);
                  },
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('تحديث الحالة'),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (resource == 'bookings' &&
                _nextBookingStage(row['workflow_stage']?.toString() ?? '') !=
                    null) ...[
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () async {
                    final changed = await _advanceBooking(row);
                    if (changed && c.mounted) Navigator.pop(c);
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    'الانتقال إلى ${_nextBookingStage(row['workflow_stage']?.toString() ?? '')}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...row.entries.map(
              (e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(_fieldLabel(e.key)),
                subtitle: SelectableText(_display(e.value)),
              ),
            ),
            if (resource == 'bookings') ...[
              const Divider(),
              FutureBuilder<Map<String, dynamic>>(
                future: widget.repository!.bookingReadiness(
                  widget.tenantId!,
                  row['id'].toString(),
                ),
                builder: (context, s) {
                  if (s.hasError) {
                    return const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.error_outline),
                      title: Text('جاهزية الحجز'),
                      subtitle: Text(
                        'تعذر حساب الجاهزية ضمن الصلاحية الحالية.',
                      ),
                    );
                  }
                  if (!s.hasData) {
                    return const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircularProgressIndicator(),
                      title: Text('جارٍ حساب جاهزية الحجز…'),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.fact_check_outlined),
                        title: Text('جاهزية الحجز والمالية'),
                      ),
                      ...s.data!.entries.map(
                        (e) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(_fieldLabel(e.key)),
                          trailing: Text(_display(e.value)),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget header(String t, String s, {Widget? action}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(s),
              ],
            ),
          ),
          ?action,
        ],
      ),
      const SizedBox(height: 20),
    ],
  );
  Widget dashboard() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header('صباح الخير — عمليات اليوم', 'ما يحتاج انتباه فريق المكتب الآن.'),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          metric('عملاء جدد', '3', Icons.person_add_alt_1),
          metric('حجوزات نشطة', '2', Icons.confirmation_number_outlined),
          metric('مغادرات قادمة', '2', Icons.flight_takeoff),
          metric('نواقص وثائق', '1', Icons.warning_amber),
          metric('رصيد للتحصيل', '6,250 ر.س', Icons.payments_outlined),
          metric('دعم مفتوح', '2', Icons.support_agent),
        ],
      ),
      const SizedBox(height: 24),
      section('الإجراءات المعلقة', [
        actionRow(
          'استكمال صورة جواز مريم أبو عمر',
          'UMR-260124',
          'اليوم',
          Icons.badge_outlined,
        ),
        actionRow(
          'متابعة تأشيرة ليان يوسف',
          'UMR-260125',
          'اليوم',
          Icons.description_outlined,
        ),
        actionRow(
          'تحصيل دفعة الحجز UMR-260125',
          '2,750 ر.س',
          'غدًا',
          Icons.receipt_long,
        ),
      ]),
      const SizedBox(height: 20),
      section('المغادرات القادمة', [
        actionRow(
          'عمرة اقتصادية — 8 أيام',
          '18 مسافرًا',
          '15 تشرين الأول',
          Icons.flight_takeoff,
        ),
        actionRow(
          'عمرة ربيع الآخر — 10 أيام',
          '12 مسافرًا',
          '22 تشرين الأول',
          Icons.flight_takeoff,
        ),
      ]),
    ],
  );
  Widget metric(String l, String v, IconData i) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 520
        ? MediaQuery.sizeOf(context).width - 48
        : 205,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(i),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v, style: Theme.of(context).textTheme.titleLarge),
                  Text(l),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget section(String t, List<Widget> c) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...c,
        ],
      ),
    ),
  );
  Widget actionRow(String t, String m, String w, IconData i) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(i),
    title: Text(t),
    subtitle: Text(m),
    trailing: Text(w),
  );
  Widget table(String title, String create, List<R> rows, List<String> cols) {
    final f = rows
        .where(
          (r) =>
              query.isEmpty ||
              r.v.any((x) => x.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header(
          title,
          'بحث، متابعة، حالات وتفاصيل تشغيلية.',
          action: FilledButton.icon(
            onPressed: () => createDialog(title),
            icon: const Icon(Icons.add),
            label: Text(create),
          ),
        ),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'بحث',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: cols.map((x) => DataColumn(label: Text(x))).toList(),
              rows: f
                  .map(
                    (r) => DataRow(
                      onSelectChanged: (_) =>
                          details(title, r.v[0], r.v.skip(1).join(' • ')),
                      cells: r.v.map((x) => DataCell(Text(x))).toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (f.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('لا توجد نتائج مطابقة.'),
          ),
      ],
    );
  }

  Widget cards(
    String title,
    List<(String, String, String)> items, {
    String? action,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        title,
        'مساحة عمل تشغيلية مترابطة.',
        action: action == null
            ? null
            : FilledButton.icon(
                onPressed: () => createDialog(title),
                icon: const Icon(Icons.add),
                label: Text(action),
              ),
      ),
      ...items.map(
        (x) => Card(
          child: ListTile(
            title: Text(x.$1),
            subtitle: Text(x.$2),
            trailing: Text(x.$3),
            onTap: () => details(x.$1, x.$2, x.$3),
          ),
        ),
      ),
    ],
  );
  Widget finance() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      header(
        'المالية التشغيلية',
        'تحصيلات العملاء، الأرصدة، الاسترداد ومستحقات الموردين.',
        action: FilledButton.icon(
          onPressed: () => createDialog('سند قبض'),
          icon: const Icon(Icons.add),
          label: const Text('سند قبض'),
        ),
      ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          metric(
            'إجمالي الحجوزات',
            '23,750 ر.س',
            Icons.account_balance_wallet_outlined,
          ),
          metric('المحصّل', '17,500 ر.س', Icons.check_circle_outline),
          metric('المتبقي', '6,250 ر.س', Icons.schedule),
          metric('مستحقات موردين', '12,400 ر.س', Icons.storefront_outlined),
        ],
      ),
      const SizedBox(height: 20),
      section('آخر الحركات', [
        actionRow(
          'سند قبض RC-884',
          'UMR-260124 • 5,000 ر.س',
          'اليوم',
          Icons.receipt,
        ),
        actionRow(
          'دفعة DP-441',
          'UMR-260125 • 2,750 ر.س',
          'أمس',
          Icons.payments,
        ),
      ]),
    ],
  );
  void createDialog(String e) => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text('إنشاء — $e'),
      content: const SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'الاسم / المرجع',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('حفظ في بيئة الاختبار'),
        ),
      ],
    ),
  );
  void details(String t, String s, String m) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(s),
            const SizedBox(height: 8),
            Text(m),
            const SizedBox(height: 20),
            const Text(
              'سجل النشاط',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.history),
              title: Text('تم تحديث الحالة'),
              subtitle: Text('بيئة اختبار — اليوم'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.person_outline),
              title: Text('المسؤول: فريق العمليات'),
            ),
          ],
        ),
      ),
    ),
  );
  String label(BusinessWorkspace w) => switch (w) {
    BusinessWorkspace.dashboard => 'لوحة العمليات',
    BusinessWorkspace.crm => 'CRM والعملاء',
    BusinessWorkspace.leads => 'العملاء المحتملون',
    BusinessWorkspace.quotes => 'العروض',
    BusinessWorkspace.bookings => 'الحجوزات',
    BusinessWorkspace.travelers => 'المسافرون',
    BusinessWorkspace.programs => 'البرامج والمغادرات',
    BusinessWorkspace.documents => 'الوثائق والتأشيرات',
    BusinessWorkspace.accommodation => 'الإقامة والغرف',
    BusinessWorkspace.transport => 'الطيران والنقل',
    BusinessWorkspace.finance => 'المالية',
    BusinessWorkspace.suppliers => 'الموردون',
    BusinessWorkspace.groups => 'المجموعات والمشرفون',
    BusinessWorkspace.tasks => 'المهام التشغيلية',
    BusinessWorkspace.support => 'الدعم',
    BusinessWorkspace.reports => 'التقارير',
  };
  IconData icon(BusinessWorkspace w) => switch (w) {
    BusinessWorkspace.dashboard => Icons.dashboard_outlined,
    BusinessWorkspace.crm => Icons.people_outline,
    BusinessWorkspace.leads => Icons.person_search_outlined,
    BusinessWorkspace.quotes => Icons.request_quote_outlined,
    BusinessWorkspace.bookings => Icons.confirmation_number_outlined,
    BusinessWorkspace.travelers => Icons.groups_outlined,
    BusinessWorkspace.programs => Icons.calendar_month_outlined,
    BusinessWorkspace.documents => Icons.badge_outlined,
    BusinessWorkspace.accommodation => Icons.hotel_outlined,
    BusinessWorkspace.transport => Icons.flight_outlined,
    BusinessWorkspace.finance => Icons.payments_outlined,
    BusinessWorkspace.suppliers => Icons.storefront_outlined,
    BusinessWorkspace.groups => Icons.supervisor_account_outlined,
    BusinessWorkspace.tasks => Icons.task_alt_outlined,
    BusinessWorkspace.support => Icons.support_agent_outlined,
    BusinessWorkspace.reports => Icons.bar_chart_outlined,
  };
}

class R {
  R(String a, String b, String c, String d, String e) : v = [a, b, c, d, e];
  final List<String> v;
}

class SearchAll extends SearchDelegate<void> {
  SearchAll(this.rows);
  final List<R> rows;
  @override
  List<Widget>? buildActions(BuildContext c) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
  @override
  Widget? buildLeading(BuildContext c) => IconButton(
    onPressed: () => close(c, null),
    icon: const Icon(Icons.arrow_forward),
  );
  @override
  Widget buildResults(BuildContext c) => results();
  @override
  Widget buildSuggestions(BuildContext c) => results();
  Widget results() {
    final q = query.toLowerCase();
    final f = rows
        .where((r) => r.v.any((x) => x.toLowerCase().contains(q)))
        .toList();
    return ListView(
      children: f
          .map(
            (r) => ListTile(
              leading: const Icon(Icons.search),
              title: Text(r.v[1]),
              subtitle: Text(r.v.join(' • ')),
            ),
          )
          .toList(),
    );
  }
}
