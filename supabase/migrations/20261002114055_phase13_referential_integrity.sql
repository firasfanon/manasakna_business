-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_referential_integrity
-- Version: 20261002114055

do $$ begin
 alter table business.customers add constraint phase13_customers_branch_fk foreign key(tenant_id,branch_id) references business.branches(tenant_id,id) on delete restrict;
 alter table business.leads add constraint phase13_leads_branch_fk foreign key(tenant_id,branch_id) references business.branches(tenant_id,id) on delete restrict;
 alter table business.departures add constraint phase13_departures_branch_fk foreign key(tenant_id,branch_id) references business.branches(tenant_id,id) on delete restrict;
 alter table business.quotes add constraint phase13_quotes_branch_fk foreign key(tenant_id,branch_id) references business.branches(tenant_id,id) on delete restrict;
 alter table business.quotes add constraint phase13_quotes_customer_fk foreign key(tenant_id,customer_id) references business.customers(tenant_id,id) on delete restrict;
 alter table business.quotes add constraint phase13_quotes_package_fk foreign key(tenant_id,package_id) references business.packages(tenant_id,id) on delete restrict;
 alter table business.quotes add constraint phase13_quotes_departure_fk foreign key(tenant_id,departure_id) references business.departures(tenant_id,id) on delete restrict;
 alter table business.bookings add constraint phase13_bookings_branch_fk foreign key(tenant_id,branch_id) references business.branches(tenant_id,id) on delete restrict;
 alter table business.finance_entries add constraint phase13_finance_branch_fk foreign key(tenant_id,branch_id) references business.branches(tenant_id,id) on delete restrict;
 alter table business.rooming_assignments add constraint phase13_rooming_traveler_fk foreign key(tenant_id,traveler_id) references business.travelers(tenant_id,id) on delete restrict;
 alter table business.ground_transports add constraint phase13_transport_supplier_fk foreign key(tenant_id,supplier_id) references business.suppliers(tenant_id,id) on delete restrict;
 alter table business.trip_groups add constraint phase13_groups_branch_fk foreign key(tenant_id,branch_id) references business.branches(tenant_id,id) on delete restrict;
exception when duplicate_object then null; end $$;
