-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_traveler_finance_fields
-- Version: 20261002114019

alter table business.travelers
 add column if not exists traveler_code text,
 add column if not exists first_name text,
 add column if not exists middle_name text,
 add column if not exists family_name text,
 add column if not exists gender text,
 add column if not exists passport_issued_on date,
 add column if not exists passport_expires_on date,
 add column if not exists passport_issuing_country text,
 add column if not exists national_id_reference text,
 add column if not exists phone text,
 add column if not exists email text,
 add column if not exists emergency_contact_name text,
 add column if not exists emergency_contact_phone text,
 add column if not exists special_requirements text,
 add column if not exists version integer not null default 1,
 add column if not exists created_by uuid,
 add column if not exists updated_by uuid,
 add column if not exists source_provenance text not null default 'commercial_company',
 add column if not exists correlation_id uuid;
alter table business.traveler_documents
 add column if not exists document_number text,
 add column if not exists issued_on date,
 add column if not exists expires_on date,
 add column if not exists issuing_country text,
 add column if not exists storage_reference text,
 add column if not exists rejection_reason text,
 add column if not exists source_provenance text not null default 'commercial_company',
 add column if not exists correlation_id uuid;
alter table business.visa_cases
 add column if not exists visa_type text not null default 'umrah',
 add column if not exists application_reference text,
 add column if not exists submitted_at timestamptz,
 add column if not exists approved_at timestamptz,
 add column if not exists issued_at timestamptz,
 add column if not exists expires_on date,
 add column if not exists rejection_reason text,
 add column if not exists source_provenance text not null default 'commercial_company',
 add column if not exists correlation_id uuid;
alter table business.finance_entries
 add column if not exists branch_id uuid,
 add column if not exists payment_method text,
 add column if not exists receipt_number text,
 add column if not exists status text not null default 'posted',
 add column if not exists due_at timestamptz,
 add column if not exists notes text,
 add column if not exists created_by uuid,
 add column if not exists source_provenance text not null default 'commercial_company',
 add column if not exists correlation_id uuid,
 add column if not exists idempotency_key text;
