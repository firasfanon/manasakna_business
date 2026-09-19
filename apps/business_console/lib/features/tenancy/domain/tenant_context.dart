enum TenantRole { owner, admin, manager, operator, viewer }

class BusinessScopes {
  const BusinessScopes._();

  static const tenantRead = 'tenant.read';
  static const tenantManage = 'tenant.manage';
  static const branchRead = 'branch.read';
  static const branchManage = 'branch.manage';
  static const staffRead = 'staff.read';
  static const staffManage = 'staff.manage';
  static const billingRead = 'billing.read';
  static const billingManage = 'billing.manage';
  static const settingsRead = 'settings.read';
  static const settingsManage = 'settings.manage';
  static const auditRead = 'audit.read';
  static const integrationsRead = 'integrations.read';
  static const integrationsManage = 'integrations.manage';

  static const prohibitedHajjSovereignScopes = <String>{
    'hajj.eligibility.manage',
    'hajj.lottery.manage',
    'hajj.quota.manage',
    'hajj.official_status.manage',
  };

  static const _roleDefaults = <TenantRole, Set<String>>{
    TenantRole.owner: {
      tenantRead,
      tenantManage,
      branchRead,
      branchManage,
      staffRead,
      staffManage,
      billingRead,
      billingManage,
      settingsRead,
      settingsManage,
      auditRead,
      integrationsRead,
      integrationsManage,
    },
    TenantRole.admin: {
      tenantRead,
      tenantManage,
      branchRead,
      branchManage,
      staffRead,
      staffManage,
      billingRead,
      settingsRead,
      settingsManage,
      auditRead,
      integrationsRead,
      integrationsManage,
    },
    TenantRole.manager: {
      tenantRead,
      branchRead,
      branchManage,
      staffRead,
      settingsRead,
      auditRead,
      integrationsRead,
    },
    TenantRole.operator: {
      tenantRead,
      branchRead,
      staffRead,
      settingsRead,
      integrationsRead,
    },
    TenantRole.viewer: {tenantRead, branchRead, settingsRead},
  };

  static Set<String> defaultsFor(TenantRole role) =>
      Set.unmodifiable(_roleDefaults[role] ?? const <String>{});
}

class TenantMembership {
  const TenantMembership({
    required this.tenantId,
    required this.tenantName,
    required this.role,
    required this.status,
    this.extraScopes = const <String>{},
    this.planCode,
  });

  final String tenantId;
  final String tenantName;
  final TenantRole role;
  final String status;
  final Set<String> extraScopes;
  final String? planCode;

  bool get isActive => status == 'active';

  Set<String> get effectiveScopes => {
    ...BusinessScopes.defaultsFor(role),
    ...extraScopes,
  };

  bool can(String scope) {
    if (BusinessScopes.prohibitedHajjSovereignScopes.contains(scope)) {
      return false;
    }
    return isActive && effectiveScopes.contains(scope);
  }

  factory TenantMembership.fromJson(Map<String, dynamic> json) {
    final roleName = (json['role'] as String? ?? 'viewer').toLowerCase();
    final role = TenantRole.values.firstWhere(
      (item) => item.name == roleName,
      orElse: () => TenantRole.viewer,
    );
    final rawScopes = json['scopes'];
    return TenantMembership(
      tenantId: json['tenant_id'] as String,
      tenantName: json['tenant_name'] as String? ?? 'Tenant',
      role: role,
      status: json['status'] as String? ?? 'inactive',
      extraScopes: rawScopes is List
          ? rawScopes.map((value) => value.toString()).toSet()
          : const <String>{},
      planCode: json['plan_code'] as String?,
    );
  }
}

class TenantContextEnvelope {
  const TenantContextEnvelope({
    required this.userId,
    required this.memberships,
  });

  final String userId;
  final List<TenantMembership> memberships;

  List<TenantMembership> get activeMemberships =>
      memberships.where((membership) => membership.isActive).toList();

  TenantMembership membershipFor(String tenantId) {
    return activeMemberships.firstWhere(
      (membership) => membership.tenantId == tenantId,
      orElse: () => throw StateError('TENANT_CONTEXT_NOT_AUTHORIZED'),
    );
  }

  factory TenantContextEnvelope.fromJson(Map<String, dynamic> json) {
    final rawMemberships = json['memberships'];
    final memberships = rawMemberships is List
        ? rawMemberships
              .whereType<Map>()
              .map(
                (item) => TenantMembership.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
        : <TenantMembership>[];
    return TenantContextEnvelope(
      userId: json['user_id'] as String? ?? '',
      memberships: memberships,
    );
  }
}
