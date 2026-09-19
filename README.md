# Manasakna Business — مناسكنا للأعمال

`MANASAKNA_BUSINESS` is the independent commercial company product that
supports company-led Umrah operations. It is intentionally separate from
`MANASAKNA_APP` and does not inherit government Hajj authority.

## Phase 6 foundation

The current foundation contains:

- Flutter Web business console under `apps/business_console`.
- Tenant / organization / branch model.
- Tenant-scoped memberships, RBAC and scopes.
- Plans, subscriptions, entitlements and usage model.
- Tenant branding/settings.
- Commercial audit model.
- Integration/provider registry.
- Supabase migration and cross-tenant isolation verification script.
- Fail-closed client configuration.

## Hard authority boundaries

- No Hajj eligibility authority.
- No Hajj lottery authority.
- No Hajj quota authority.
- No Hajj official pilgrim-status authority.
- No direct cross-plane database access.
- No shared government/commercial super-admin.
- No service-role secret in any client bundle.

## Development

The active foundation branch is:

`task/manasakna-business-foundation-v1`

Flutter console:

```powershell
cd apps\business_console
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Remote database provisioning remains a separate controlled step within Phase 6.
