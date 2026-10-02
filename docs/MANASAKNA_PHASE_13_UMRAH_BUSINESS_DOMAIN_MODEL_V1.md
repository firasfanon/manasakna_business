# Manasakna Business — Phase 13 Umrah Domain Model V1
Status: engineering contract; non-production only.
Presentation rule: the current Phase 13 UI is frozen as the presentation shell. Sample fields and sample rows are not the final schema.
Authority: commercial Umrah company tenant only. Hajj sovereign authority is prohibited.
Data rule: synthetic/approved non-production data only; no real-user data.

## Aggregate map
Tenant 1→N Branch; Tenant 1→N Membership.
Customer 1→N Lead; Lead 1→N Quote; Quote 1→N QuoteItem.
Package 1→N Departure; Quote N→1 Package/Departure where selected.
Customer 1→N Booking; Quote 1→N Booking; Departure 1→N Booking.
Booking N↔N Traveler through BookingTraveler.
Traveler 1→N TravelerDocument; Traveler 1→0..1 VisaCase.
Booking 1→N WorkflowEvent; Booking 1→N FinanceEntry.
Booking 1→N RoomingAssignment / Flight / GroundTransport / OperationalTask / SupportCase.
Departure 1→N TripGroup; Group N↔N Booking; Group 1→N Supervisor.
Supplier 1→N Contract / Property / Payable; Property 1→N RoomingAssignment.

## Field dictionary — identity / CRM
Customer required: tenant_id, full_name, customer_type, status, preferred_locale, source_channel, data_classification.
Customer optional: branch_id, customer_code, full_name_en, phone, whatsapp, email, nationality, residence, city, assignee, tags, consent.
Lead required: tenant_id, customer_id, source, status. Conditional: lost_reason when lost; budget currency when budget supplied.
Quote required: tenant_id, lead_id, currency, total_amount, price_snapshot, snapshot_hash, status.
Quote optional/conditional: customer/package/departure, quote_code, validity, pricing components, terms, inclusions/exclusions.
QuoteItem required: quote, type, description, quantity, unit amount; supplier optional.

## Programs / bookings / travelers
Package required: name, duration, base price, currency, status. Optional: code, itinerary, inclusions, exclusions, terms, sales window.
Departure required: package, dates, capacity, status. Optional: branch, code, meeting point, deadline; booked_capacity derived/guarded.
Booking required: quote, departure, customer, status, workflow_stage, total, currency, payment_condition.
Booking optional: branch, assignee, external ref, cancellation reason/time, idempotency/correlation.
Traveler required: full_name, passport_reference, synthetic classification. Production-shaped optional fields include split name, gender, DOB, passport issue/expiry/country, national ID ref, contact/emergency/special requirements.
Document required: traveler, type, reference, verification status. Conditional rejection reason when rejected.
Visa required: traveler, status, visa_type. External authority fields remain observational and provenance-bearing.

## Operations / finance
Accommodation: booking + property + stay dates + room; traveler/room type/occupancy/status conditional.
Air: booking, flight number, route, times; segment, airline, PNR, ticket/cabin/baggage/status.
Transport: booking, mode, pickup/dropoff/time; supplier/vehicle/driver/capacity/status.
FinanceEntry: booking, type, amount, currency, synthetic classification; branch/method/receipt/status/due/notes/idempotency.
Supplier: name, type, status; production-shaped code/legal/contact/location/payment terms.
Support/Task: booking-scoped, priority/status/assignment/timestamps/correlation.
All mutable core records carry timestamps; critical aggregates add version, actor and provenance fields.

## State machines
Lead: new → qualified → quoted → booked | lost.
Quote: draft → sent → accepted | rejected | expired.
Departure: planned → open → closed → departed → returned; cancellation is terminal.
Booking workflow: booking → travelers → documents → visa → program → accommodation → air → transport → payments → departure_readiness → departed → in_trip → returned → closed; cancelled is terminal.
Document: pending → verified | rejected | expired.
Visa: not_started → prepared → submitted → under_review → approved → issued → expired; rejected is terminal/rework by explicit action.
Task: open → in_progress → done | cancelled. Support: open → pending → resolved → closed.
Finance: pending → posted | voided. Supplier payable: open → approved → paid | cancelled.

## Validation / integrity
Cross-tenant references use composite tenant_id + id foreign keys where available.
No backward or skipped booking workflow transitions; readiness prerequisites fail closed.
Amounts are non-negative; currency is ISO-like 3 uppercase letters; date windows are ordered.
Capacity cannot be negative or exceed departure capacity. Quote totals retain immutable snapshot provenance.
Every state-changing RPC requires tenant scope, writes audit evidence, and carries correlation/idempotency where material.
RLS remains enabled; base tables are not directly granted to anon/authenticated. Client mutation goes through bounded RPCs.

## Required / optional / conditional principle
Required = necessary to create a valid aggregate in its earliest lifecycle state.
Optional = legitimate business information that may be unknown at creation.
Conditional = mandatory before a specific transition (passport before document-ready, visa case before visa stage, confirmed operational allocations before departure readiness, financial requirement according to payment condition).
This distinction is authoritative; the presentation shell may show fewer fields than the domain record.

## Phase 12 reconciliation
Existing Phase 6/7/12 tables are retained and extended additively. No parallel replacement schema.
New Phase 13 tables: quote_items and booking_workflow_events.
Existing synthetic-only classification constraints remain intact; Phase 13 does not authorize real data.
Journey Context and App compatibility contract remain unchanged unless separately authorized.

## Phase 13 non-production migration readback
Applied schema/domain migrations: phase13_booking_workflow_events; phase13_sales_identity_fields; phase13_quote_booking_fields; phase13_traveler_finance_fields; phase13_operations_fields; phase13_validation_indexes; phase13_referential_integrity; phase13_booking_state_machine; phase13_readiness_dashboard.
Applied security/CRUD migrations: phase13_tenant_negative_test_harness; phase13_bounded_crud_core; phase13_bounded_status_task; phase13_bounded_support_finance; phase13_bounded_lead_traveler; phase13_bounded_list_expansion.
Schema readback: PASS. business tables now include quote_items and booking_workflow_events with RLS enabled.
Phase 13 tenant negative harness execution: PASS. Same-tenant access allowed; cross-tenant access denied; Hajj scope denied; direct anon/authenticated sampled base-table access denied.
Phase 13 RPC matrix: PASS for customer, lead, traveler, task, support, finance, status and all bounded list resources. Cross-tenant RPC attempts were denied.
Synthetic transaction test: PASS for Customer → Lead → Quote → Booking; real-user classification was rejected; invalid backward state transition was rejected.
Finance idempotency: PASS; replay returned the same record with idempotent_replay=true.
All synthetic verification transactions were rolled back; post-test residue readback = 0.
Production/store/real-user-data authority: NO.
