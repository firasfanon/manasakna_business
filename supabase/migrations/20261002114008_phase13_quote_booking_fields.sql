-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_quote_booking_fields
-- Version: 20261002114008

alter table business.quotes
 add column if not exists branch_id uuid,
 add column if not exists customer_id uuid,
 add column if not exists package_id uuid,
 add column if not exists departure_id uuid,
 add column if not exists quote_code text,
 add column if not exists version_number integer not null default 1,
 add column if not exists subtotal_amount numeric(14,2) not null default 0,
 add column if not exists discount_amount numeric(14,2) not null default 0,
 add column if not exists tax_amount numeric(14,2) not null default 0,
 add column if not exists fee_amount numeric(14,2) not null default 0,
 add column if not exists payment_terms text,
 add column if not exists cancellation_terms text,
 add column if not exists inclusions jsonb not null default '[]'::jsonb,
 add column if not exists exclusions jsonb not null default '[]'::jsonb,
 add column if not exists accepted_at timestamptz,
 add column if not exists created_by uuid,
 add column if not exists updated_by uuid,
 add column if not exists correlation_id uuid;
create table if not exists business.quote_items(
 id uuid primary key default gen_random_uuid(),
 tenant_id uuid not null references business.tenants(id) on delete cascade,
 quote_id uuid not null,
 item_type text not null,
 description text not null,
 quantity numeric(12,2) not null default 1 check(quantity>0),
 unit_amount numeric(14,2) not null check(unit_amount>=0),
 total_amount numeric(14,2) generated always as(quantity*unit_amount) stored,
 supplier_id uuid,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now(),
 unique(tenant_id,id),
 foreign key(tenant_id,quote_id) references business.quotes(tenant_id,id) on delete cascade,
 foreign key(tenant_id,supplier_id) references business.suppliers(tenant_id,id) on delete restrict
);
alter table business.quote_items enable row level security;
revoke all on business.quote_items from public,anon,authenticated;
alter table business.bookings
 add column if not exists branch_id uuid,
 add column if not exists workflow_stage text not null default 'booking',
 add column if not exists total_amount numeric(14,2) not null default 0,
 add column if not exists currency text not null default 'USD',
 add column if not exists payment_condition text not null default 'deposit_required',
 add column if not exists assigned_user_id uuid,
 add column if not exists cancellation_reason text,
 add column if not exists cancelled_at timestamptz,
 add column if not exists external_reference text,
 add column if not exists correlation_id uuid,
 add column if not exists idempotency_key text,
 add column if not exists version integer not null default 1,
 add column if not exists created_by uuid,
 add column if not exists updated_by uuid;
