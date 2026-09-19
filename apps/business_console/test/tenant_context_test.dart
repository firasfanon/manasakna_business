import 'package:flutter_test/flutter_test.dart';
import 'package:manasakna_business_console/features/tenancy/domain/tenant_context.dart';

void main() {
  group('tenant authority isolation', () {
    const tenantA = TenantMembership(
      tenantId: 'tenant-a',
      tenantName: 'شركة ألف',
      role: TenantRole.owner,
      status: 'active',
    );

    const tenantB = TenantMembership(
      tenantId: 'tenant-b',
      tenantName: 'شركة باء',
      role: TenantRole.viewer,
      status: 'active',
    );

    test('membership lookup never falls through to another tenant', () {
      const envelope = TenantContextEnvelope(
        userId: 'user-a',
        memberships: [tenantA],
      );

      expect(envelope.membershipFor('tenant-a').tenantId, 'tenant-a');
      expect(
        () => envelope.membershipFor('tenant-b'),
        throwsA(isA<StateError>()),
      );
    });

    test('role scopes remain tenant-local', () {
      expect(tenantA.can(BusinessScopes.settingsManage), isTrue);
      expect(tenantB.can(BusinessScopes.settingsManage), isFalse);
    });

    test('Hajj sovereign scopes are prohibited for every commercial role', () {
      for (final role in TenantRole.values) {
        final membership = TenantMembership(
          tenantId: 'tenant-${role.name}',
          tenantName: role.name,
          role: role,
          status: 'active',
          extraScopes: BusinessScopes.prohibitedHajjSovereignScopes,
        );

        for (final scope in BusinessScopes.prohibitedHajjSovereignScopes) {
          expect(
            membership.can(scope),
            isFalse,
            reason: '${role.name} must not receive $scope',
          );
        }
      }
    });
  });
}
