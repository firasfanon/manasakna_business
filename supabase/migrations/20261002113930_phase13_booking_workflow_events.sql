-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_booking_workflow_events
-- Version: 20261002113930

create table if not exists business.booking_workflow_events (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_id uuid not null,
  from_stage text,
  to_stage text not null,
  actor_user_id uuid,
  reason text,
  correlation_id uuid,
  idempotency_key text,
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now(),
  foreign key (tenant_id, booking_id)
    references business.bookings(tenant_id, id) on delete cascade,
  unique (tenant_id, idempotency_key)
);
alter table business.booking_workflow_events enable row level security;
revoke all on business.booking_workflow_events from public, anon, authenticated;
create index if not exists booking_workflow_events_booking_idx
  on business.booking_workflow_events(tenant_id, booking_id, occurred_at desc);
