import 'package:flutter/material.dart';

enum BusinessWorkspace {
  dashboard,
  crm,
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
  support,
  reports,
}

class BusinessProductShell extends StatefulWidget {
  const BusinessProductShell({
    super.key,
    this.tenantName = 'شركة العمرة التجريبية',
    this.nonProduction = true,
    this.onSignOut,
  });
  final String tenantName;
  final bool nonProduction;
  final VoidCallback? onSignOut;
  @override
  State<BusinessProductShell> createState() => _BusinessProductShellState();
}

class _BusinessProductShellState extends State<BusinessProductShell> {
  BusinessWorkspace selected = BusinessWorkspace.dashboard;
  String query = '';
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
      child: switch (selected) {
        BusinessWorkspace.dashboard => dashboard(),
        BusinessWorkspace.crm => table(
          'CRM والعملاء المحتملون',
          'عميل محتمل جديد',
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
        BusinessWorkspace.bookings => table('الحجوزات', 'حجز جديد', bookings, [
          'رقم الحجز',
          'العميل',
          'البرنامج',
          'الحالة',
          'المغادرة',
        ]),
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
          ('UMR-260124 — مريم أبو عمر', 'صورة الجواز ناقصة', 'يتطلب إجراء'),
          ('UMR-260125 — ليان يوسف', 'ملف التأشيرة مكتمل', 'قيد المتابعة'),
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
          ('UMR-260125', 'مقطع جوي غير مربوط', 'النقل الأرضي بانتظار البرنامج'),
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
    BusinessWorkspace.support => 'الدعم',
    BusinessWorkspace.reports => 'التقارير',
  };
  IconData icon(BusinessWorkspace w) => switch (w) {
    BusinessWorkspace.dashboard => Icons.dashboard_outlined,
    BusinessWorkspace.crm => Icons.people_outline,
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
