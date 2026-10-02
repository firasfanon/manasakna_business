# Manasakna Business — Phase 13

## Purpose
Transform the Business console from a capability/governance surface into an operator-first Umrah office product experience.

## Product surface
The primary UI is now a persistent Arabic RTL business shell with workspaces for Dashboard, CRM, Quotes, Bookings, Travelers, Programs/Departures, Documents/Visas, Accommodation, Air/Transport, Operational Finance, Suppliers, Groups/Supervisors, Support, and Reports.

## Governance boundary
Governance remains enforced by existing tenancy, authority, provider and fail-closed contracts. It is not the default business home screen. Hajj sovereign authority remains prohibited for the commercial plane.

## Data boundary
Phase 13 uses synthetic or previously approved non-production data only. No production endpoint, production transaction, store release, or real user data is authorized.

## Workflow contract
The bounded Umrah office lifecycle is:
Lead → Quote → Approved → Booking → Travelers → Documents → Visa → Program → Accommodation → Air → Transport → Payments → Departure Readiness → Departed → In Trip → Returned → Closed.

Skipped or backward state transitions fail closed.

## Compatibility
The traveler App baseline remains frozen and is not mutated by this phase. Existing Business Phase 9–12 authority, provider, tenancy, diagnostics and integration tests remain regression gates.

## Acceptance evidence
Phase 13 adds desktop and 390px widget coverage, operator navigation checks, end-to-end workflow transition tests, full Business regression suite, analyzer review, release Web build, and visual UAT evidence.
