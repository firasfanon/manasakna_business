-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_operations_fields
-- Version: 20261002114033

alter table business.suppliers
 add column if not exists supplier_code text,
 add column if not exists legal_name text,
 add column if not exists registration_number text,
 add column if not exists contact_name text,
 add column if not exists phone text,
 add column if not exists email text,
 add column if not exists country text,
 add column if not exists city text,
 add column if not exists payment_terms text,
 add column if not exists notes text,
 add column if not exists version integer not null default 1,
 add column if not exists created_by uuid,
 add column if not exists updated_by uuid;
alter table business.properties
 add column if not exists property_code text,
 add column if not exists address text,
 add column if not exists star_rating numeric(2,1),
 add column if not exists distance_to_haram_m integer,
 add column if not exists contact_phone text,
 add column if not exists status text not null default 'active';
alter table business.rooming_assignments
 add column if not exists traveler_id uuid,
 add column if not exists room_type text,
 add column if not exists occupancy integer,
 add column if not exists status text not null default 'reserved',
 add column if not exists notes text;
alter table business.flights
 add column if not exists segment_type text not null default 'outbound',
 add column if not exists airline_code text,
 add column if not exists booking_reference text,
 add column if not exists ticket_status text not null default 'planned',
 add column if not exists cabin_class text,
 add column if not exists baggage_allowance text,
 add column if not exists status text not null default 'scheduled';
alter table business.ground_transports
 add column if not exists supplier_id uuid,
 add column if not exists vehicle_reference text,
 add column if not exists driver_name text,
 add column if not exists driver_phone text,
 add column if not exists capacity integer,
 add column if not exists status text not null default 'planned';
alter table business.trip_groups
 add column if not exists branch_id uuid,
 add column if not exists capacity integer,
 add column if not exists status text not null default 'forming';
alter table business.supervisors
 add column if not exists user_id uuid,
 add column if not exists email text,
 add column if not exists role_title text,
 add column if not exists status text not null default 'assigned';
alter table business.operational_tasks
 add column if not exists task_type text not null default 'general',
 add column if not exists priority text not null default 'normal',
 add column if not exists completed_at timestamptz,
 add column if not exists correlation_id uuid;
alter table business.support_cases
 add column if not exists case_code text,
 add column if not exists priority text not null default 'normal',
 add column if not exists assigned_user_id uuid,
 add column if not exists resolution text,
 add column if not exists resolved_at timestamptz,
 add column if not exists correlation_id uuid;
alter table business.supplier_payables
 add column if not exists due_on date,
 add column if not exists reference text,
 add column if not exists approved_by uuid,
 add column if not exists paid_at timestamptz,
 add column if not exists correlation_id uuid;
