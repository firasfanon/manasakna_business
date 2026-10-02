-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_bounded_support_finance
-- Version: 20261002115650

create or replace function public.rpc_business_phase13_save_support_v1(p_tenant_id uuid,p_case_id uuid,p_booking_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v business.support_cases%rowtype;
begin
 perform business_private.assert_scope(p_tenant_id,'support.manage');
 if not exists(select 1 from business.bookings where tenant_id=p_tenant_id and id=p_booking_id) then raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501'; end if;
 if coalesce(trim(p_payload->>'category'),'')='' or coalesce(trim(p_payload->>'summary'),'')='' then raise exception 'SUPPORT_CATEGORY_AND_SUMMARY_REQUIRED' using errcode='23514'; end if;
 if p_case_id is null then
  insert into business.support_cases(tenant_id,booking_id,traveler_id,category,summary,status,case_code,priority,correlation_id)
  values(p_tenant_id,p_booking_id,nullif(p_payload->>'traveler_id','')::uuid,trim(p_payload->>'category'),trim(p_payload->>'summary'),'open','CASE-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),coalesce(nullif(p_payload->>'priority',''),'normal'),gen_random_uuid()) returning * into v;
 else
  update business.support_cases set category=trim(p_payload->>'category'),summary=trim(p_payload->>'summary'),priority=coalesce(nullif(p_payload->>'priority',''),priority),updated_at=now() where tenant_id=p_tenant_id and id=p_case_id returning * into v;
  if v.id is null then raise exception 'SUPPORT_NOT_IN_TENANT' using errcode='42501'; end if;
 end if;
 perform business_private.write_audit(p_tenant_id,'phase13.support.save','support_case',v.id::text,'success','{}'::jsonb); return to_jsonb(v);
end $$;
revoke all on function public.rpc_business_phase13_save_support_v1(uuid,uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_support_v1(uuid,uuid,uuid,jsonb) to authenticated;

create or replace function public.rpc_business_phase13_save_finance_v1(p_tenant_id uuid,p_booking_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v business.finance_entries%rowtype; k text:=nullif(p_payload->>'idempotency_key','');
begin
 perform business_private.assert_scope(p_tenant_id,'finance.manage');
 if not exists(select 1 from business.bookings where tenant_id=p_tenant_id and id=p_booking_id) then raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501'; end if;
 if coalesce(p_payload->>'data_classification','synthetic')<>'synthetic' then raise exception 'REAL_USER_DATA_PROHIBITED' using errcode='42501'; end if;
 if k is not null then select * into v from business.finance_entries where tenant_id=p_tenant_id and idempotency_key=k limit 1; if v.id is not null then return to_jsonb(v)||jsonb_build_object('idempotent_replay',true); end if; end if;
 insert into business.finance_entries(tenant_id,booking_id,entry_type,amount,currency,reference,data_classification,payment_method,receipt_number,status,due_at,notes,created_by,correlation_id,idempotency_key)
 values(p_tenant_id,p_booking_id,p_payload->>'entry_type',(p_payload->>'amount')::numeric,upper(p_payload->>'currency'),nullif(p_payload->>'reference',''),'synthetic',nullif(p_payload->>'payment_method',''),nullif(p_payload->>'receipt_number',''),coalesce(nullif(p_payload->>'status',''),'posted'),nullif(p_payload->>'due_at','')::timestamptz,nullif(p_payload->>'notes',''),auth.uid(),gen_random_uuid(),k) returning * into v;
 perform business_private.write_audit(p_tenant_id,'phase13.finance.save','finance_entry',v.id::text,'success',jsonb_build_object('entry_type',v.entry_type,'amount',v.amount,'currency',v.currency)); return to_jsonb(v)||jsonb_build_object('idempotent_replay',false);
end $$;
revoke all on function public.rpc_business_phase13_save_finance_v1(uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_finance_v1(uuid,uuid,jsonb) to authenticated;
