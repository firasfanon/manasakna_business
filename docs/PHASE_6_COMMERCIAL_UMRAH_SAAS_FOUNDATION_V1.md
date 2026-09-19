# MANASAKNA BUSINESS — Phase 6 Commercial Umrah SaaS Foundation V1

## Authority

Phase 6 is authorized on the independent `MANASAKNA_BUSINESS` project.
The source project `MANASAKNA_APP` remains the unified traveler app and
government-led Hajj plane. This repository does not inherit that authority.

## Foundation scope

Phase 6 establishes the commercial control plane:

1. tenant / organization / branch;
2. staff memberships;
3. tenant-scoped RBAC and explicit scopes;
4. plans / subscriptions / entitlements / usage;
5. tenant settings and branding;
6. commercial audit;
7. integration/provider registry;
8. a fail-closed web console;
9. a separate Supabase database target;
10. contract-only future integration with Manasakna.

## Security invariants

Direct client table CRUD is not the API model. Commercial tables live under the
`business` schema, direct anonymous/authenticated table access is revoked,
RLS is enabled and forced, and public client access is through narrowly scoped
versioned RPC functions.

Every tenant action requires an authenticated user and an active membership.
Scope checks are server-side. Any scope beginning with sovereign Hajj authority
semantics is explicitly rejected by the commercial authorization helper.

The client accepts only `SUPABASE_URL` and
`SUPABASE_PUBLISHABLE_KEY`. Service-role material is prohibited from the
client and repository.

## G6 acceptance

G6 requires at least two synthetic tenants to be isolated end-to-end.

Acceptance is two-layered:

- application/domain isolation tests;
- database/RPC isolation tests on the dedicated Supabase project.

Until the dedicated Supabase project is provisioned and the migration plus
negative isolation script pass remotely, G6 remains open even when local
Flutter validation is green.

## Explicit exclusions

No production, real traveler data, real Nusuk, real payment provider, store
release, Hajj sovereign mutation, or direct database access to Manasakna is
authorized by Phase 6 foundation work.
