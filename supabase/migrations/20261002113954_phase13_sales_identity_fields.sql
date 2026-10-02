-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_sales_identity_fields
-- Version: 20261002113954

alter table business.customers
 add column if not exists branch_id uuid,
 add column if not exists customer_code text,
 add column if not exists customer_type text not null default 'individual',
 add column if not exists full_name_en text,
 add column if not exists whatsapp text,
 add column if not exists nationality text,
 add column if not exists country_of_residence text,
 add column if not exists city text,
 add column if not exists preferred_locale text not null default 'ar',
 add column if not exists source_channel text not null default 'manual',
 add column if not exists assigned_user_id uuid,
 add column if not exists tags text[] not null default '{}'::text[],
 add column if not exists communication_consent boolean not null default false,
 add column if not exists archived_at timestamptz,
 add column if not exists version integer not null default 1,
 add column if not exists created_by uuid,
 add column if not exists updated_by uuid,
 add column if not exists source_provenance text not null default 'commercial_company',
 add column if not exists correlation_id uuid;
alter table business.leads
 add column if not exists branch_id uuid,
 add column if not exists assigned_user_id uuid,
 add column if not exists expected_travelers integer,
 add column if not exists budget_min numeric(14,2),
 add column if not exists budget_max numeric(14,2),
 add column if not exists budget_currency text,
 add column if not exists next_follow_up_at timestamptz,
 add column if not exists lost_reason text,
 add column if not exists version integer not null default 1,
 add column if not exists created_by uuid,
 add column if not exists updated_by uuid,
 add column if not exists correlation_id uuid;
alter table business.packages
 add column if not exists package_code text,
 add column if not exists itinerary jsonb not null default '[]'::jsonb,
 add column if not exists inclusions jsonb not null default '[]'::jsonb,
 add column if not exists exclusions jsonb not null default '[]'::jsonb,
 add column if not exists terms text,
 add column if not exists sales_start date,
 add column if not exists sales_end date,
 add column if not exists version integer not null default 1,
 add column if not exists created_by uuid,
 add column if not exists updated_by uuid;
alter table business.departures
 add column if not exists branch_id uuid,
 add column if not exists departure_code text,
 add column if not exists meeting_point text,
 add column if not exists registration_deadline timestamptz,
 add column if not exists booked_capacity integer not null default 0,
 add column if not exists version integer not null default 1,
 add column if not exists created_by uuid,
 add column if not exists updated_by uuid;
