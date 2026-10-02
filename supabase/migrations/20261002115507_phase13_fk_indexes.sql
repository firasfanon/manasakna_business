-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_fk_indexes
-- Version: 20261002115507

create index if not exists phase13_booking_travelers_traveler_fk_idx on business.booking_travelers(tenant_id,traveler_id);
create index if not exists phase13_bookings_quote_fk_idx on business.bookings(tenant_id,quote_id);
create index if not exists phase13_bookings_departure_fk_idx on business.bookings(tenant_id,departure_id);
create index if not exists phase13_bookings_customer_fk_idx on business.bookings(tenant_id,customer_id);
create index if not exists phase13_bookings_branch_fk_idx on business.bookings(tenant_id,branch_id);
create index if not exists phase13_departures_package_fk_idx on business.departures(tenant_id,package_id);
create index if not exists phase13_departures_branch_fk_idx on business.departures(tenant_id,branch_id);
create index if not exists phase13_leads_customer_fk_idx on business.leads(tenant_id,customer_id);
create index if not exists phase13_leads_branch_fk_idx on business.leads(tenant_id,branch_id);
create index if not exists phase13_quotes_lead_fk_idx on business.quotes(tenant_id,lead_id);
create index if not exists phase13_quotes_branch_fk_idx on business.quotes(tenant_id,branch_id);
create index if not exists phase13_quotes_customer_fk_idx on business.quotes(tenant_id,customer_id);
create index if not exists phase13_quotes_package_fk_idx on business.quotes(tenant_id,package_id);
create index if not exists phase13_quotes_departure_fk_idx on business.quotes(tenant_id,departure_id);
create index if not exists phase13_quote_items_quote_fk_idx on business.quote_items(tenant_id,quote_id);
create index if not exists phase13_quote_items_supplier_fk_idx on business.quote_items(tenant_id,supplier_id);
create index if not exists phase13_rooming_property_fk_idx on business.rooming_assignments(tenant_id,property_id);
create index if not exists phase13_rooming_traveler_fk_idx on business.rooming_assignments(tenant_id,traveler_id);
create index if not exists phase13_finance_branch_fk_idx on business.finance_entries(tenant_id,branch_id);
create index if not exists phase13_transport_supplier_fk_idx on business.ground_transports(tenant_id,supplier_id);
create index if not exists phase13_groups_branch_fk_idx on business.trip_groups(tenant_id,branch_id);
