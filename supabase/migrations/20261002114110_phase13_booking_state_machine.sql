-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_booking_state_machine
-- Version: 20261002114110

create or replace function business_private.phase13_booking_stage_rank(p_stage text)
returns integer language sql immutable set search_path='' as $$
 select case p_stage when 'booking' then 10 when 'travelers' then 20 when 'documents' then 30 when 'visa' then 40
 when 'program' then 50 when 'accommodation' then 60 when 'air' then 70 when 'transport' then 80 when 'payments' then 90
 when 'departure_readiness' then 100 when 'departed' then 110 when 'in_trip' then 120 when 'returned' then 130 when 'closed' then 140
 when 'cancelled' then 999 else -1 end
$$;
create or replace function public.rpc_business_advance_booking_stage_v1(
 p_tenant_id uuid,p_booking_id uuid,p_to_stage text,p_reason text default null,p_idempotency_key text default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_from text; v_rank_from int; v_rank_to int; v_event_id bigint;
begin
 perform business_private.assert_scope(p_tenant_id,'booking.manage');
 select workflow_stage into v_from from business.bookings where tenant_id=p_tenant_id and id=p_booking_id for update;
 if v_from is null then raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501'; end if;
 if p_idempotency_key is not null then
  select id into v_event_id from business.booking_workflow_events where tenant_id=p_tenant_id and idempotency_key=p_idempotency_key;
  if v_event_id is not null then return jsonb_build_object('booking_id',p_booking_id,'stage',v_from,'idempotent_replay',true); end if;
 end if;
 v_rank_from:=business_private.phase13_booking_stage_rank(v_from); v_rank_to:=business_private.phase13_booking_stage_rank(p_to_stage);
 if p_to_stage='cancelled' then null;
 elsif v_rank_to <> v_rank_from+10 then raise exception 'INVALID_BOOKING_STAGE_TRANSITION:%->%',v_from,p_to_stage using errcode='22023'; end if;
 if p_to_stage='travelers' and not exists(select 1 from business.booking_travelers where tenant_id=p_tenant_id and booking_id=p_booking_id) then raise exception 'TRAVELER_REQUIRED' using errcode='23514'; end if;
 if p_to_stage='documents' and exists(select 1 from business.booking_travelers bt where bt.tenant_id=p_tenant_id and bt.booking_id=p_booking_id and not exists(select 1 from business.traveler_documents d where d.tenant_id=bt.tenant_id and d.traveler_id=bt.traveler_id and d.document_type='passport')) then raise exception 'PASSPORT_DOCUMENT_REQUIRED' using errcode='23514'; end if;
 if p_to_stage='visa' and exists(select 1 from business.booking_travelers bt where bt.tenant_id=p_tenant_id and bt.booking_id=p_booking_id and not exists(select 1 from business.visa_cases v where v.tenant_id=bt.tenant_id and v.traveler_id=bt.traveler_id)) then raise exception 'VISA_CASE_REQUIRED' using errcode='23514'; end if;
 if p_to_stage='accommodation' and not exists(select 1 from business.rooming_assignments r where r.tenant_id=p_tenant_id and r.booking_id=p_booking_id) then raise exception 'ACCOMMODATION_REQUIRED' using errcode='23514'; end if;
 if p_to_stage='air' and not exists(select 1 from business.flights f where f.tenant_id=p_tenant_id and f.booking_id=p_booking_id) then raise exception 'FLIGHT_REQUIRED' using errcode='23514'; end if;
 if p_to_stage='transport' and not exists(select 1 from business.ground_transports g where g.tenant_id=p_tenant_id and g.booking_id=p_booking_id) then raise exception 'TRANSPORT_REQUIRED' using errcode='23514'; end if;
 update business.bookings set workflow_stage=p_to_stage,updated_at=now(),version=version+1 where tenant_id=p_tenant_id and id=p_booking_id;
 insert into business.booking_workflow_events(tenant_id,booking_id,from_stage,to_stage,actor_user_id,reason,correlation_id,idempotency_key)
 values(p_tenant_id,p_booking_id,v_from,p_to_stage,auth.uid(),p_reason,gen_random_uuid(),p_idempotency_key) returning id into v_event_id;
 perform business_private.write_audit(p_tenant_id,'booking.stage.advance','booking',p_booking_id::text,'success',jsonb_build_object('from',v_from,'to',p_to_stage,'event_id',v_event_id));
 return jsonb_build_object('booking_id',p_booking_id,'from_stage',v_from,'to_stage',p_to_stage,'event_id',v_event_id,'idempotent_replay',false);
end $$;
revoke all on function public.rpc_business_advance_booking_stage_v1(uuid,uuid,text,text,text) from public,anon;
grant execute on function public.rpc_business_advance_booking_stage_v1(uuid,uuid,text,text,text) to authenticated;
