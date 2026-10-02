-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_readiness_dashboard
-- Version: 20261002114124

create or replace function public.rpc_business_booking_readiness_v1(p_tenant_id uuid,p_booking_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_travelers bigint; v_missing_passports bigint; v_visa_ready bigint; v_balance numeric; v_total numeric; v_currency text;
begin
 perform business_private.assert_scope(p_tenant_id,'booking.read');
 if not exists(select 1 from business.bookings where tenant_id=p_tenant_id and id=p_booking_id) then raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501'; end if;
 select count(*) into v_travelers from business.booking_travelers where tenant_id=p_tenant_id and booking_id=p_booking_id;
 select count(*) into v_missing_passports from business.booking_travelers bt where bt.tenant_id=p_tenant_id and bt.booking_id=p_booking_id and not exists(select 1 from business.traveler_documents d where d.tenant_id=bt.tenant_id and d.traveler_id=bt.traveler_id and d.document_type='passport' and d.verification_status='verified');
 select count(*) into v_visa_ready from business.booking_travelers bt join business.visa_cases v on v.tenant_id=bt.tenant_id and v.traveler_id=bt.traveler_id where bt.tenant_id=p_tenant_id and bt.booking_id=p_booking_id and v.status in('approved','issued');
 select total_amount,currency into v_total,v_currency from business.bookings where tenant_id=p_tenant_id and id=p_booking_id;
 select coalesce(sum(case entry_type when 'payment' then amount when 'refund' then -amount else 0 end),0) into v_balance from business.finance_entries where tenant_id=p_tenant_id and booking_id=p_booking_id and status='posted';
 return jsonb_build_object(
 'travelers',v_travelers,'documents_ready',v_travelers>0 and v_missing_passports=0,'visas_ready',v_travelers>0 and v_visa_ready=v_travelers,
 'accommodation_ready',exists(select 1 from business.rooming_assignments where tenant_id=p_tenant_id and booking_id=p_booking_id and status in('reserved','confirmed')),
 'air_ready',exists(select 1 from business.flights where tenant_id=p_tenant_id and booking_id=p_booking_id and ticket_status in('reserved','ticketed')),
 'transport_ready',exists(select 1 from business.ground_transports where tenant_id=p_tenant_id and booking_id=p_booking_id and status='confirmed'),
 'total_amount',v_total,'paid_amount',v_balance,'outstanding_amount',greatest(coalesce(v_total,0)-v_balance,0),'currency',v_currency,
 'financially_ready',v_balance>=coalesce(v_total,0));
end $$;
create or replace function public.rpc_business_phase13_dashboard_v1(p_tenant_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
 perform business_private.assert_scope(p_tenant_id,'booking.read');
 return jsonb_build_object(
 'active_leads',(select count(*) from business.leads where tenant_id=p_tenant_id and status not in('booked','lost')),
 'open_quotes',(select count(*) from business.quotes where tenant_id=p_tenant_id and status in('draft','sent')),
 'active_bookings',(select count(*) from business.bookings where tenant_id=p_tenant_id and workflow_stage not in('closed','cancelled')),
 'upcoming_departures',(select count(*) from business.departures where tenant_id=p_tenant_id and start_date>=current_date and status in('planned','open','closed')),
 'missing_passports',(select count(*) from business.booking_travelers bt where bt.tenant_id=p_tenant_id and not exists(select 1 from business.traveler_documents d where d.tenant_id=bt.tenant_id and d.traveler_id=bt.traveler_id and d.document_type='passport' and d.verification_status='verified')),
 'open_tasks',(select count(*) from business.operational_tasks where tenant_id=p_tenant_id and status in('open','in_progress')),
 'open_support',(select count(*) from business.support_cases where tenant_id=p_tenant_id and status in('open','pending')),
 'customer_receivables',(select coalesce(sum(case entry_type when 'charge' then amount when 'payment' then -amount when 'refund' then amount else 0 end),0) from business.finance_entries where tenant_id=p_tenant_id and status='posted'),
 'supplier_payables',(select coalesce(sum(amount),0) from business.supplier_payables where tenant_id=p_tenant_id and status in('open','approved')));
end $$;
revoke all on function public.rpc_business_booking_readiness_v1(uuid,uuid) from public,anon;
grant execute on function public.rpc_business_booking_readiness_v1(uuid,uuid) to authenticated;
revoke all on function public.rpc_business_phase13_dashboard_v1(uuid) from public,anon;
grant execute on function public.rpc_business_phase13_dashboard_v1(uuid) to authenticated;
