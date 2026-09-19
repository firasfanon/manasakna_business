# Manasakna Business — Phase 7 Umrah Commercial MVP V1

## Objective

Operate a complete synthetic Umrah commercial journey from Lead to a
provenance-preserving Commercial Umrah Journey Context while keeping
government Hajj sovereignty outside this product.

## Mega Batch A — Commercial core and booking backbone

Implemented as a forward migration only; the applied Phase 6 migration remains
immutable.

- CRM customers and leads.
- Quotes with immutable price snapshots and SHA-256 snapshot hashes.
- Packages and departures.
- Booking lifecycle.
- Traveler / booking assignment.
- Synthetic-only traveler records for the current authority stage.
- Document verification workflow.
- Visa workflow with explicit authority-source metadata.
- Operational finance entries: charge, payment and refund.
- Booking balance read model.
- Versioned, tenant-scoped RPC surface.

## Mega Batch B — Trip operations and Journey Context

- Suppliers and contracts.
- Hotels/properties and rooming assignments.
- Flights and ground transport.
- Trip groups and supervisors.
- Operational tasks and support cases.
- Supplier payables as operational finance only.
- Pipeline summary.
- Commercial Umrah Journey Context V1.

The Journey Context identifies its source authority as commercial company,
carries provenance and freshness, and never creates eligibility, lottery,
quota, or official Hajj status.

## Client surface

The Flutter Web console exposes a responsive RTL operating overview with:

- pipeline indicators;
- governed MVP module map;
- booking list;
- Commercial Umrah Journey Context preview.

No real traveler records are introduced by Phase 7. Database acceptance uses
synthetic records inside rollback transactions.

## G7 acceptance

G7 requires:

1. Lead -> Quote -> Booking -> Traveler -> Documents/Visa -> Payment.
2. Package/departure -> hotel/room -> flight -> transport -> group/supervisor.
3. Support and operational tasks.
4. Commercial Umrah Journey Context V1.
5. Two synthetic tenants isolated end-to-end.
6. Quote price snapshot immutability.
7. Hajj sovereign scopes denied.
8. Direct client table access denied.
9. Flutter analyze/test/web build pass.
10. Narrow and desktop RTL widget UAT pass.

## Explicit exclusions

Production, real data, real Nusuk, real payment processing, general-ledger
accounting, store release, and cross-plane delivery into MANASAKNA_APP remain
outside Phase 7 authority.
