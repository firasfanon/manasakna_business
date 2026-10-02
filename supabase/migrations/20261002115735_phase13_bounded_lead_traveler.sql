-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_bounded_lead_traveler
-- Version: 20261002115735

create or replace function public.rpc_business_phase13_save_lead_v1(p_tenant_id uuid,p_lead_id uuid,p_customer_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v business.leads%rowtype;
begin
 perform business_private.assert_scope(p_tenant_id,'crm.manage');
 if not exists(select 1 from business.customers where tenant_id=p_tenant_id and id=p_customer_id) then raise exception 'CUSTOMER_NOT_IN_TENANT' using errcode='42501'; end if;
 if p_lead_id is null then
  insert into business.leads(tenant_id,customer_id,source,status,notes,expected_travelers,budget_min,budget_max,budget_currency,next_follow_up_at,created_by,updated_by,correlation_id)
  values(p_tenant_id,p_customer_id,coalesce(nullif(p_payload->>'source',''),'manual'),'new',nullif(p_payload->>'notes',''),nullif(p_payload->>'expected_travelers','')::int,nullif(p_payload->>'budget_min','')::numeric,nullif(p_payload->>'budget_max','')::numeric,nullif(upper(p_payload->>'budget_currency'),''),nullif(p_payload->>'next_follow_up_at','')::timestamptz,auth.uid(),auth.uid(),gen_random_uuid()) returning * into v;
 else
  update business.leads set notes=nullif(p_payload->>'notes',''),expected_travelers=nullif(p_payload->>'expected_travelers','')::int,budget_min=nullif(p_payload->>'budget_min','')::numeric,budget_max=nullif(p_payload->>'budget_max','')::numeric,budget_currency=nullif(upper(p_payload->>'budget_currency'),''),next_follow_up_at=nullif(p_payload->>'next_follow_up_at','')::timestamptz,updated_at=now(),updated_by=auth.uid(),version=version+1 where tenant_id=p_tenant_id and id=p_lead_id returning * into v;
  if v.id is null then raise exception 'LEAD_NOT_IN_TENANT' using errcode='42501'; end if;
 end if;
 perform business_private.write_audit(p_tenant_id,'phase13.lead.save','lead',v.id::text,'success','{}'::jsonb); return to_jsonb(v);
end $$;
revoke all on function public.rpc_business_phase13_save_lead_v1(uuid,uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_lead_v1(uuid,uuid,uuid,jsonb) to authenticated;

create or replace function public.rpc_business_phase13_save_traveler_v1(p_tenant_id uuid,p_booking_id uuid,p_traveler_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v business.travelers%rowtype;
begin
 perform business_private.assert_scope(p_tenant_id,'traveler.manage');
 if not exists(select 1 from business.bookings where tenant_id=p_tenant_id and id=p_booking_id) then raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501'; end if;
 if coalesce(p_payload->>'data_classification','synthetic')<>'synthetic' then raise exception 'REAL_USER_DATA_PROHIBITED' using errcode='42501'; end if;
 if coalesce(trim(p_payload->>'full_name'),'')='' or coalesce(trim(p_payload->>'passport_reference'),'')='' then raise exception 'TRAVELER_NAME_AND_PASSPORT_REQUIRED' using errcode='23514'; end if;
 if p_traveler_id is null then
  insert into business.travelers(tenant_id,full_name,passport_reference,nationality,date_of_birth,data_classification,traveler_code,gender,passport_expires_on,phone,email,emergency_contact_name,emergency_contact_phone,special_requirements,created_by,updated_by,correlation_id)
  values(p_tenant_id,trim(p_payload->>'full_name'),trim(p_payload->>'passport_reference'),nullif(p_payload->>'nationality',''),nullif(p_payload->>'date_of_birth','')::date,'synthetic','TRV-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),nullif(p_payload->>'gender',''),nullif(p_payload->>'passport_expires_on','')::date,nullif(p_payload->>'phone',''),nullif(p_payload->>'email',''),nullif(p_payload->>'emergency_contact_name',''),nullif(p_payload->>'emergency_contact_phone',''),nullif(p_payload->>'special_requirements',''),auth.uid(),auth.uid(),gen_random_uuid()) returning * into v;
  insert into business.booking_travelers(tenant_id,booking_id,traveler_id,traveler_role) values(p_tenant_id,p_booking_id,v.id,coalesce(nullif(p_payload->>'traveler_role',''),'primary'));
 else
  update business.travelers set full_name=trim(p_payload->>'full_name'),passport_reference=trim(p_payload->>'passport_reference'),nationality=nullif(p_payload->>'nationality',''),date_of_birth=nullif(p_payload->>'date_of_birth','')::date,gender=nullif(p_payload->>'gender',''),passport_expires_on=nullif(p_payload->>'passport_expires_on','')::date,phone=nullif(p_payload->>'phone',''),email=nullif(p_payload->>'email',''),emergency_contact_name=nullif(p_payload->>'emergency_contact_name',''),emergency_contact_phone=nullif(p_payload->>'emergency_contact_phone',''),special_requirements=nullif(p_payload->>'special_requirements',''),updated_at=now(),updated_by=auth.uid(),version=version+1 where tenant_id=p_tenant_id and id=p_traveler_id returning * into v;
  if v.id is null then raise exception 'TRAVELER_NOT_IN_TENANT' using errcode='42501'; end if;
 end if;
 perform business_private.write_audit(p_tenant_id,'phase13.traveler.save','traveler',v.id::text,'success','{}'::jsonb); return to_jsonb(v);
end $$;
revoke all on function public.rpc_business_phase13_save_traveler_v1(uuid,uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_traveler_v1(uuid,uuid,uuid,jsonb) to authenticated;
