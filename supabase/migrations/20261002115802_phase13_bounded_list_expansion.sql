-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_bounded_list_expansion
-- Version: 20261002115802

create or replace function public.rpc_business_phase13_list_v1(p_tenant_id uuid,p_resource text,p_limit integer default 100)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v jsonb;
begin
 if p_limit<1 or p_limit>500 then raise exception 'INVALID_LIMIT' using errcode='22023'; end if;
 if p_resource='customers' then perform business_private.assert_scope(p_tenant_id,'crm.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.customers where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='leads' then perform business_private.assert_scope(p_tenant_id,'crm.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.leads where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='quotes' then perform business_private.assert_scope(p_tenant_id,'quote.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.quotes where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='packages' then perform business_private.assert_scope(p_tenant_id,'package.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.packages where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='departures' then perform business_private.assert_scope(p_tenant_id,'package.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.departures where tenant_id=p_tenant_id order by start_date desc limit p_limit)x;
 elsif p_resource='bookings' then perform business_private.assert_scope(p_tenant_id,'booking.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.bookings where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='travelers' then perform business_private.assert_scope(p_tenant_id,'traveler.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.travelers where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='documents' then perform business_private.assert_scope(p_tenant_id,'document.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.traveler_documents where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='visas' then perform business_private.assert_scope(p_tenant_id,'visa.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.visa_cases where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='finance' then perform business_private.assert_scope(p_tenant_id,'finance.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.finance_entries where tenant_id=p_tenant_id order by occurred_at desc limit p_limit)x;
 elsif p_resource='suppliers' then perform business_private.assert_scope(p_tenant_id,'supplier.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.suppliers where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='accommodation' then perform business_private.assert_scope(p_tenant_id,'operations.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.rooming_assignments where tenant_id=p_tenant_id order by created_at desc limit p_limit)x;
 elsif p_resource='flights' then perform business_private.assert_scope(p_tenant_id,'operations.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.flights where tenant_id=p_tenant_id order by departure_at desc limit p_limit)x;
 elsif p_resource='transport' then perform business_private.assert_scope(p_tenant_id,'operations.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.ground_transports where tenant_id=p_tenant_id order by scheduled_at desc limit p_limit)x;
 elsif p_resource='groups' then perform business_private.assert_scope(p_tenant_id,'operations.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.trip_groups where tenant_id=p_tenant_id order by created_at desc limit p_limit)x;
 elsif p_resource='tasks' then perform business_private.assert_scope(p_tenant_id,'operations.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.operational_tasks where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='support' then perform business_private.assert_scope(p_tenant_id,'support.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.support_cases where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 else raise exception 'UNSUPPORTED_RESOURCE:%',p_resource using errcode='22023'; end if;
 return v;
end $$;
