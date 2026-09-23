# Manasakna Phase 9 — Cross-Plane Integration Gateway V1

## Scope

This batch introduces the governed source-code boundary for exchanging an authorized
traveler-safe Umrah projection from MANASAKNA_BUSINESS to MANASAKNA_APP.

It does not merge databases, tenants, authorities, or systems of record.

## Business-side controls

- Exact versioned contract: manasakna-cross-plane-gateway-v1.
- Explicit consumer service identity and audience.
- Required scope: journey.read.traveler_projection.
- Any hajj.* scope fails closed.
- Umrah-only commercial gateway.
- Requested fields are allow-listed.
- Finance, payments, margins, commissions, supplier payables, CRM identity,
  passport references, and document references are prohibited from the traveler
  projection.
- Idempotency keys replay the same cached result but reject subject collisions.
- Audit events record allowed, replayed, denied, and failed outcomes without
  turning the audit channel into an authority source.
- The existing tenant-scoped commercial Journey Context remains the source input.

## Current execution boundary

- No new Supabase migration.
- No direct cross-plane database access.
- No service-role material in the client.
- No production deployment.
- No real traveler data.
- No real Nusuk or payment integration.
- No Phase 10 external-provider implementation.
- No real service secret provisioning.

The batch therefore proves G9 contract, minimization, authorization-shape,
idempotency, replay, audit, and negative-access behavior with synthetic/non-
production fixtures. Live service identity provisioning and network deployment
remain separate controlled gates.