# Manasakna Phase 10 — Official / External Integrations V1

Status: synthetic non-production execution candidate.

## Scope

This batch introduces a governed provider-integration control plane for four provider classes: official/regulatory, messaging, payment, and airline/hotel/travel providers.

It does **not** activate a real provider. No real endpoint, credential, user data, payment, Nusuk write, live webhook, production deployment, or store release is included.

## Authority invariants

- Hajj root authority remains government.
- Manasakna Business never becomes Hajj sovereign authority.
- Commercial Umrah authority remains company-tenant scoped.
- External providers are not hidden sources of truth outside their declared domain.
- Unknown or ambiguous authority fails closed.
- Direct cross-plane database access remains prohibited.

## Admission and resilience

Every request is bound to an explicit provider descriptor, operation allow-list, synthetic fixture marker, data classification, provenance model, timeout, bounded attempts, idempotency key, audit outcome, and explicit unavailable fallback.

All synthetic responses carry `synthetic=true` provenance and must not claim authoritative real-world state.

## Webhook boundary

The included webhook gate is a synthetic authenticity/replay fixture only. The fixed synthetic signature is test material, not a production secret or cryptographic scheme.

## Real-provider gate

Real Nusuk or regulatory integration requires verified official access, contract, and authorization. Real payment, messaging, travel-provider access, credentials, live callbacks, and real data each require separate explicit admission and execution authority.
