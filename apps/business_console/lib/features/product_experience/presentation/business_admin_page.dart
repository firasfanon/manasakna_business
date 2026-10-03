import 'package:flutter/material.dart';

import '../../../core/design/manasakna_design_system.dart';
import '../data/business_product_repository.dart';

class BusinessAdminPage extends StatefulWidget {
  const BusinessAdminPage({
    super.key,
    required this.repository,
    required this.tenantId,
    required this.tenantName,
  });
  final BusinessProductRepository repository;
  final String tenantId;
  final String tenantName;

  @override
  State<BusinessAdminPage> createState() => _BusinessAdminPageState();
}

class _BusinessAdminPageState extends State<BusinessAdminPage> {
  int revision = 0;

  Future<List<Map<String, dynamic>>> _load(String resource) =>
      widget.repository.adminList(widget.tenantId, resource);

  void _refresh() => setState(() => revision++);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('إدارة مساحة العمل'),
      actions: [
        IconButton(
          tooltip: 'تحديث',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListView(
      key: ValueKey(revision),
      padding: const EdgeInsets.all(20),
      children: [
        _hero(context),
        const SizedBox(height: 18),
        _settingsSection(context),
        const SizedBox(height: 18),
        _branchesSection(context),
        const SizedBox(height: 18),
        _staffSection(context),
      ],
    ),
  );

  Widget _hero(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: ManasaknaDesign.panel(context),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 12,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tenantName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('الهوية والفروع والأدوار ضمن حدود الصلاحيات الحالية.'),
          ],
        ),
        const Chip(label: Text('Non-Production')),
      ],
    ),
  );

  Widget _settingsSection(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _load('settings'),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LinearProgressIndicator();
          }
          if (snapshot.hasError) return _error(snapshot.error);
          final row = (snapshot.data ?? const []).isEmpty
              ? <String, dynamic>{}
              : snapshot.data!.first;
          return _sectionCard(
            context,
            icon: Icons.palette_outlined,
            title: 'الهوية وإعدادات المكتب',
            subtitle: 'اسم العلامة ووسائل الدعم واللغة الأساسية.',
            action: FilledButton.tonalIcon(
              onPressed: () => _editSettings(row),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل'),
            ),
            children: [
              _kv('الاسم العربي', row['brand_name_ar']),
              _kv('الاسم الإنجليزي', row['brand_name_en']),
              _kv('اللغة', row['primary_locale']),
              _kv('بريد الدعم', row['support_email']),
              _kv('هاتف الدعم', row['support_phone']),
            ],
          );
        },
      );

  Widget _branchesSection(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _load('branches'),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LinearProgressIndicator();
      }
      if (snapshot.hasError) return _error(snapshot.error);
      final rows = snapshot.data ?? const [];
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _load('organizations'),
        builder: (context, orgSnapshot) {
          final organizations = orgSnapshot.data ?? const [];
          return _sectionCard(
            context,
            icon: Icons.account_tree_outlined,
            title: 'الفروع',
            subtitle: 'إدارة الفروع التابعة للمؤسسة الحالية.',
            action: FilledButton.tonalIcon(
              onPressed: organizations.isEmpty
                  ? null
                  : () => _editBranch(null, organizations),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('فرع جديد'),
            ),
            children: rows.isEmpty
                ? const [ListTile(title: Text('لا توجد فروع.'))]
                : rows
                      .map(
                        (row) => ListTile(
                          leading: const Icon(
                            Icons.store_mall_directory_outlined,
                          ),
                          title: Text(row['name']?.toString() ?? 'فرع'),
                          subtitle: Text(
                            '${row['code'] ?? ''} • ${row['timezone'] ?? ''}',
                          ),
                          trailing: IconButton(
                            tooltip: 'تعديل',
                            onPressed: () => _editBranch(row, organizations),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                      )
                      .toList(),
          );
        },
      );
    },
  );

  Widget _staffSection(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _load('staff'),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const LinearProgressIndicator();
      }
      if (snapshot.hasError) return _error(snapshot.error);
      final rows = snapshot.data ?? const [];
      return _sectionCard(
        context,
        icon: Icons.manage_accounts_outlined,
        title: 'المستخدمون والأدوار',
        subtitle:
            'تعديل دور وحالة الأعضاء الموجودين. دعوة مستخدم جديد تتطلب قناة Auth Admin رسمية.',
        children: rows.isEmpty
            ? const [ListTile(title: Text('لا توجد عضويات ظاهرة.'))]
            : rows
                  .map(
                    (row) => ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_outline),
                      ),
                      title: Text(
                        (row['email']?.toString().isNotEmpty ?? false)
                            ? row['email'].toString()
                            : row['user_id'].toString(),
                      ),
                      subtitle: Text(
                        'الدور: ${row['role']} • الحالة: ${row['status']}',
                      ),
                      trailing: IconButton(
                        tooltip: 'إدارة العضوية',
                        onPressed: () => _editStaff(row),
                        icon: const Icon(Icons.admin_panel_settings_outlined),
                      ),
                    ),
                  )
                  .toList(),
      );
    },
  );

  Widget _sectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
    required List<Widget> children,
  }) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: ManasaknaDesign.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(subtitle),
                  ],
                ),
              ),
              ?action,
            ],
          ),
          const Divider(height: 28),
          ...children,
        ],
      ),
    ),
  );

  Widget _kv(String label, Object? value) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text(
      value?.toString().trim().isNotEmpty == true ? value.toString() : '—',
    ),
  );

  Widget _error(Object? error) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('تعذر تحميل إعدادات الإدارة: $error'),
    ),
  );

  Future<void> _editSettings(Map<String, dynamic> row) async {
    final ar = TextEditingController(text: row['brand_name_ar']?.toString());
    final en = TextEditingController(text: row['brand_name_en']?.toString());
    final email = TextEditingController(text: row['support_email']?.toString());
    final phone = TextEditingController(text: row['support_phone']?.toString());
    var locale = row['primary_locale']?.toString() ?? 'ar';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إعدادات الهوية'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: ar,
                  decoration: const InputDecoration(labelText: 'الاسم العربي'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: en,
                  decoration: const InputDecoration(
                    labelText: 'الاسم الإنجليزي',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'بريد الدعم'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'هاتف الدعم'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: locale,
                  decoration: const InputDecoration(
                    labelText: 'اللغة الأساسية',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ar', child: Text('العربية')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) => locale = value ?? locale,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              await widget.repository.adminSave(
                widget.tenantId,
                'settings',
                id: widget.tenantId,
                payload: {
                  'brand_name_ar': ar.text.trim(),
                  'brand_name_en': en.text.trim(),
                  'support_email': email.text.trim(),
                  'support_phone': phone.text.trim(),
                  'primary_locale': locale,
                  'settings': row['settings'] ?? <String, dynamic>{},
                },
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _editBranch(
    Map<String, dynamic>? row,
    List<Map<String, dynamic>> organizations,
  ) async {
    final code = TextEditingController(text: row?['code']?.toString());
    final name = TextEditingController(text: row?['name']?.toString());
    final timezone = TextEditingController(
      text: row?['timezone']?.toString() ?? 'Asia/Hebron',
    );
    var organizationId =
        row?['organization_id']?.toString() ??
        organizations.first['id'].toString();
    var active = row?['is_active'] != false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(row == null ? 'فرع جديد' : 'تعديل الفرع'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: organizationId,
                  decoration: const InputDecoration(labelText: 'المؤسسة'),
                  items: organizations
                      .map(
                        (x) => DropdownMenuItem(
                          value: x['id'].toString(),
                          child: Text(x['name']?.toString() ?? 'مؤسسة'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      organizationId = value ?? organizationId,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: code,
                  decoration: const InputDecoration(labelText: 'رمز الفرع'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'اسم الفرع'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: timezone,
                  decoration: const InputDecoration(
                    labelText: 'المنطقة الزمنية',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                  title: const Text('فرع فعال'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.repository.adminSave(
                  widget.tenantId,
                  'branch',
                  id: row?['id']?.toString(),
                  payload: {
                    'organization_id': organizationId,
                    'code': code.text.trim(),
                    'name': name.text.trim(),
                    'timezone': timezone.text.trim(),
                    'is_active': active.toString(),
                  },
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _refresh();
  }

  Future<void> _editStaff(Map<String, dynamic> row) async {
    var role = row['role']?.toString() ?? 'viewer';
    var status = row['status']?.toString() ?? 'active';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إدارة العضوية'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'الدور'),
                  items: const [
                    DropdownMenuItem(value: 'owner', child: Text('مالك')),
                    DropdownMenuItem(value: 'admin', child: Text('مدير نظام')),
                    DropdownMenuItem(value: 'manager', child: Text('مدير')),
                    DropdownMenuItem(value: 'operator', child: Text('مشغل')),
                    DropdownMenuItem(value: 'viewer', child: Text('مشاهد')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => role = value ?? role),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'الحالة'),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('فعال')),
                    DropdownMenuItem(value: 'suspended', child: Text('موقوف')),
                    DropdownMenuItem(value: 'revoked', child: Text('ملغى')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => status = value ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                await widget.repository.adminSave(
                  widget.tenantId,
                  'staff',
                  id: row['id'].toString(),
                  payload: {'role': role, 'status': status},
                );
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _refresh();
  }
}
