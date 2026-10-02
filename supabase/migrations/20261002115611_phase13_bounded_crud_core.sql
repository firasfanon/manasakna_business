-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_bounded_crud_core
-- Version: 20261002115611

create or replace function public.rpc_business_phase13_list_v1(p_tenant_id uuid,p_resource text,p_limit integer default 100)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v jsonb;
begin
 if p_limit<1 or p_limit>500 then raise exception 'INVALID_LIMIT' using errcode='22023'; end if;
 if p_resource='customers' then perform business_private.assert_scope(p_tenant_id,'crm.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.customers where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='leads' then perform business_private.assert_scope(p_tenant_id,'crm.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.leads where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='quotes' then perform business_private.assert_scope(p_tenant_id,'quote.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.quotes where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='bookings' then perform business_private.assert_scope(p_tenant_id,'booking.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.bookings where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='travelers' then perform business_private.assert_scope(p_tenant_id,'traveler.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.travelers where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='documents' then perform business_private.assert_scope(p_tenant_id,'document.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.traveler_documents where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='visas' then perform business_private.assert_scope(p_tenant_id,'visa.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.visa_cases where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='finance' then perform business_private.assert_scope(p_tenant_id,'finance.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.finance_entries where tenant_id=p_tenant_id order by occurred_at desc limit p_limit)x;
 elsif p_resource='tasks' then perform business_private.assert_scope(p_tenant_id,'operations.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.operational_tasks where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 elsif p_resource='support' then perform business_private.assert_scope(p_tenant_id,'support.read'); select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v from (select * from business.support_cases where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
 else raise exception 'UNSUPPORTED_RESOURCE:%',p_resource using errcode='22023'; end if;
 return v;
end $$;
revoke all on function public.rpc_business_phase13_list_v1(uuid,text,integer) from public,anon;
grant execute on function public.rpc_business_phase13_list_v1(uuid,text,integer) to authenticated;

create or replace function public.rpc_business_phase13_save_customer_v1(p_tenant_id uuid,p_customer_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v business.customers%rowtype;
begin
 perform business_private.assert_scope(p_tenant_id,'crm.manage');
 if coalesce(trim(p_payload->>'full_name'),'')='' then raise exception 'FULL_NAME_REQUIRED' using errcode='23514'; end if;
 if coalesce(p_payload->>'data_classification','synthetic')<>'synthetic' then raise exception 'REAL_USER_DATA_PROHIBITED' using errcode='42501'; end if;
 if p_customer_id is null then
  insert into business.customers(tenant_id,full_name,phone,email,customer_type,full_name_en,whatsapp,nationality,country_of_residence,city,preferred_locale,source_channel,tags,communication_consent,data_classification,created_by,updated_by,correlation_id)
  values(p_tenant_id,trim(p_payload->>'full_name'),nullif(p_payload->>'phone',''),nullif(p_payload->>'email',''),coalesce(nullif(p_payload->>'customer_type',''),'individual'),nullif(p_payload->>'full_name_en',''),nullif(p_payload->>'whatsapp',''),nullif(p_payload->>'nationality',''),nullif(p_payload->>'country_of_residence',''),nullif(p_payload->>'city',''),coalesce(nullif(p_payload->>'preferred_locale',''),'ar'),coalesce(nullif(p_payload->>'source_channel',''),'manual'),coalesce(array(select jsonb_array_elements_text(coalesce(p_payload->'tags','[]'::jsonb))),'{}'::text[]),coalesce((p_payload->>'communication_consent')::boolean,false),'synthetic',auth.uid(),auth.uid(),gen_random_uuid()) returning * into v;
 else
  update business.customers set full_name=trim(p_payload->>'full_name'),phone=nullif(p_payload->>'phone',''),email=nullif(p_payload->>'email',''),full_name_en=nullif(p_payload->>'full_name_en',''),whatsapp=nullif(p_payload->>'whatsapp',''),nationality=nullif(p_payload->>'nationality',''),country_of_residence=nullif(p_payload->>'country_of_residence',''),city=nullif(p_payload->>'city',''),updated_by=auth.uid(),updated_at=now(),version=version+1 where tenant_id=p_tenant_id and id=p_customer_id returning * into v;
  if v.id is null then raise exception 'CUSTOMER_NOT_IN_TENANT' using errcode='42501'; end if;
 end if;
 perform business_private.write_audit(p_tenant_id,'phase13.customer.save','customer',v.id::text,'success',jsonb_build_object('classification','synthetic'));
 return to_jsonb(v);
end $$;
revoke all on function public.rpc_business_phase13_save_customer_v1(uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_customer_v1(uuid,uuid,jsonb) to authenticated;
