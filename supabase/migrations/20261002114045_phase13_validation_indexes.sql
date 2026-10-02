-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_validation_indexes
-- Version: 20261002114045

do $$ begin
 alter table business.customers add constraint phase13_customers_type_chk check(customer_type in('individual','family','organization'));
 alter table business.customers add constraint phase13_customers_locale_chk check(preferred_locale in('ar','en'));
 alter table business.customers add constraint phase13_customers_version_chk check(version>0);
 alter table business.leads add constraint phase13_leads_expected_chk check(expected_travelers is null or expected_travelers>0);
 alter table business.leads add constraint phase13_leads_budget_chk check((budget_min is null or budget_min>=0) and (budget_max is null or budget_max>=0) and (budget_min is null or budget_max is null or budget_max>=budget_min));
 alter table business.packages add constraint phase13_packages_sales_window_chk check(sales_start is null or sales_end is null or sales_end>=sales_start);
 alter table business.departures add constraint phase13_departures_booked_capacity_chk check(booked_capacity>=0 and booked_capacity<=capacity);
 alter table business.quotes add constraint phase13_quotes_amounts_chk check(subtotal_amount>=0 and discount_amount>=0 and tax_amount>=0 and fee_amount>=0);
 alter table business.bookings add constraint phase13_bookings_stage_chk check(workflow_stage in('booking','travelers','documents','visa','program','accommodation','air','transport','payments','departure_readiness','departed','in_trip','returned','closed','cancelled'));
 alter table business.bookings add constraint phase13_bookings_payment_condition_chk check(payment_condition in('none','deposit_required','full_payment_required'));
 alter table business.travelers add constraint phase13_travelers_gender_chk check(gender is null or gender in('male','female','unspecified'));
 alter table business.finance_entries add constraint phase13_finance_status_chk check(status in('pending','posted','voided'));
 alter table business.properties add constraint phase13_properties_status_chk check(status in('active','inactive'));
 alter table business.rooming_assignments add constraint phase13_rooming_status_chk check(status in('planned','reserved','confirmed','checked_in','checked_out','cancelled'));
 alter table business.flights add constraint phase13_flight_segment_chk check(segment_type in('outbound','return','internal'));
 alter table business.flights add constraint phase13_flight_ticket_chk check(ticket_status in('planned','reserved','ticketed','cancelled'));
 alter table business.flights add constraint phase13_flight_status_chk check(status in('scheduled','confirmed','delayed','departed','arrived','cancelled'));
 alter table business.ground_transports add constraint phase13_transport_status_chk check(status in('planned','confirmed','in_progress','completed','cancelled'));
 alter table business.trip_groups add constraint phase13_group_status_chk check(status in('forming','ready','departed','returned','closed','cancelled'));
 alter table business.operational_tasks add constraint phase13_task_priority_chk check(priority in('low','normal','high','urgent'));
 alter table business.support_cases add constraint phase13_support_priority_chk check(priority in('low','normal','high','urgent'));
exception when duplicate_object then null; end $$;
create index if not exists phase13_customers_branch_idx on business.customers(tenant_id,branch_id,status);
create index if not exists phase13_leads_followup_idx on business.leads(tenant_id,status,next_follow_up_at);
create index if not exists phase13_quotes_status_idx on business.quotes(tenant_id,status,valid_until);
create index if not exists phase13_bookings_stage_idx on business.bookings(tenant_id,workflow_stage,status);
create index if not exists phase13_tasks_due_idx on business.operational_tasks(tenant_id,status,due_at);
create index if not exists phase13_support_status_idx on business.support_cases(tenant_id,status,priority);
create index if not exists phase13_finance_booking_idx on business.finance_entries(tenant_id,booking_id,occurred_at desc);
