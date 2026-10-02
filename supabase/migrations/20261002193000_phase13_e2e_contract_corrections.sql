-- Phase 13 E2E corrections materialized from verified live non-production state.
-- Scope: quote item generated total, dashboard receivables, synthetic E2E harness.

CREATE OR REPLACE FUNCTION business_private.phase13_office_journey_e2e_once()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 t uuid:=gen_random_uuid(); u uuid:=gen_random_uuid(); dep uuid:=gen_random_uuid(); pkg uuid:=gen_random_uuid();
 c jsonb; l jsonb; q jsonb; b jsonb; tr jsonb; f1 jsonb; f2 jsonb; ready jsonb; dash jsonb;
 cid uuid; lid uuid; qid uuid; bid uuid; ok boolean:=false; result jsonb;
begin
 insert into business.tenants(id,slug,display_name)
 values(t,'p13-e2e-'||replace(t::text,'-',''),'Phase13 synthetic office E2E');
 insert into business.memberships(tenant_id,user_id,role,status) values(t,u,'owner','active');
 perform set_config('request.jwt.claim.sub',u::text,true);
 insert into business.packages(id,tenant_id,package_code,name,duration_days,base_price,currency,status,created_by,updated_by)
 values(pkg,t,'P13-E2E','Phase13 synthetic package',10,1000,'SAR','active',u,u);
 insert into business.departures(id,tenant_id,package_id,departure_code,start_date,end_date,capacity,status,created_by,updated_by)
 values(dep,t,pkg,'P13-E2E-DEP',current_date+30,current_date+40,20,'open',u,u);

 c:=public.rpc_business_phase13_save_customer_v1(t,null,jsonb_build_object(
  'full_name','Synthetic Phase13 Customer','customer_type','individual','preferred_locale','ar',
  'source_channel','synthetic_e2e','tags','[]'::jsonb,'communication_consent',false,
  'data_classification','synthetic','source_provenance','phase13_office_journey_e2e'));
 cid:=(c->>'id')::uuid;
 if not exists(select 1 from business.customers where tenant_id=t and id=cid) then
  raise exception 'E2E_CUSTOMER_PERSISTENCE_FAILED' using errcode='23514';
 end if;
 l:=public.rpc_business_phase13_save_lead_v1(t,null,cid,jsonb_build_object(
  'source','synthetic_e2e','notes','phase13 office journey','expected_travelers',1,
  'data_classification','synthetic','source_provenance','phase13_office_journey_e2e'));
 lid:=(l->>'id')::uuid;
 q:=public.rpc_business_phase13_save_quote_v1(t,null,lid,jsonb_build_object(
  'quote_code','P13-E2E-Q','currency','SAR','subtotal_amount',1000,'discount_amount',0,
  'tax_amount',0,'fee_amount',0,'departure_id',dep,'package_id',pkg));
 qid:=(q->>'id')::uuid;
 perform public.rpc_business_phase13_save_quote_item_v1(t,null,qid,jsonb_build_object(
  'item_type','package','description','Synthetic Umrah package','quantity',1,'unit_amount',1000));
 perform public.rpc_business_phase13_update_status_v1(t,'quote',qid,'sent','e2e');
 perform public.rpc_business_phase13_update_status_v1(t,'quote',qid,'accepted','e2e');
 b:=public.rpc_business_phase13_save_booking_v1(t,null,qid,jsonb_build_object(
  'booking_code','P13-E2E-B','departure_id',dep,'payment_condition','full_payment_required',
  'idempotency_key','p13-e2e-booking'));
 bid:=(b->>'id')::uuid;
 tr:=public.rpc_business_phase13_save_traveler_v1(t,bid,null,jsonb_build_object(
  'full_name','Synthetic Traveler','passport_reference','P13-PASS-001',
  'data_classification','synthetic','source_provenance','phase13_office_journey_e2e'));
 f1:=public.rpc_business_phase13_save_finance_v1(t,bid,jsonb_build_object(
  'entry_type','payment','amount',1000,'currency','SAR','reference','P13-E2E-PAY',
  'idempotency_key','p13-e2e-finance'));
 f2:=public.rpc_business_phase13_save_finance_v1(t,bid,jsonb_build_object(
  'entry_type','payment','amount',1000,'currency','SAR','reference','P13-E2E-PAY',
  'idempotency_key','p13-e2e-finance'));
 ready:=public.rpc_business_booking_readiness_v1(t,bid);
 dash:=public.rpc_business_phase13_dashboard_v1(t);
 ok:=(f1->>'id')=(f2->>'id')
   and coalesce((f2->>'idempotent_replay')::boolean,false)
   and (ready->>'paid_amount')::numeric=1000
   and (ready->>'outstanding_amount')::numeric=0
   and coalesce((ready->>'financially_ready')::boolean,false)
   and (dash->>'active_bookings')::int=1;
 if not ok then raise exception 'PHASE13_OFFICE_JOURNEY_E2E_FAILED' using errcode='23514'; end if;
 result:=jsonb_build_object(
   'pass',true,'customer_id',cid,'lead_id',lid,'quote_id',qid,'booking_id',bid,
   'traveler_id',tr->>'id','finance_id',f1->>'id','finance_replay',f2->>'idempotent_replay',
   'readiness',ready,'dashboard',dash);
 raise exception using errcode='P0001',message='PHASE13_E2E_ROLLBACK:'||result::text;
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_business_phase13_dashboard_v1(p_tenant_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
 'customer_receivables',(select greatest(coalesce((select sum(total_amount) from business.bookings where tenant_id=p_tenant_id and workflow_stage<>'cancelled'),0)-coalesce((select sum(case entry_type when 'payment' then amount when 'refund' then -amount else 0 end) from business.finance_entries where tenant_id=p_tenant_id and status='posted'),0),0)),
 'supplier_payables',(select coalesce(sum(amount),0) from business.supplier_payables where tenant_id=p_tenant_id and status in('open','approved')));
end $function$;

CREATE OR REPLACE FUNCTION public.rpc_business_phase13_save_quote_item_v1(p_tenant_id uuid, p_item_id uuid, p_quote_id uuid, p_payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v business.quote_items%rowtype; v_status text; v_subtotal numeric;
begin
 perform business_private.assert_scope(p_tenant_id,'quote.manage');
 select status into v_status from business.quotes where tenant_id=p_tenant_id and id=p_quote_id;
 if v_status is null then raise exception 'QUOTE_NOT_IN_TENANT' using errcode='42501'; end if;
 if v_status<>'draft' then raise exception 'QUOTE_NOT_EDITABLE' using errcode='23514'; end if;
 if coalesce(trim(p_payload->>'item_type'),'')='' or coalesce(trim(p_payload->>'description'),'')='' then
  raise exception 'QUOTE_ITEM_FIELDS_REQUIRED' using errcode='23514';
 end if;
 if nullif(p_payload->>'unit_amount','') is null or (p_payload->>'unit_amount')::numeric<0 then
  raise exception 'QUOTE_ITEM_AMOUNT_REQUIRED' using errcode='23514';
 end if;
 if p_item_id is null then
  insert into business.quote_items(tenant_id,quote_id,item_type,description,quantity,unit_amount,supplier_id,metadata)
  values(p_tenant_id,p_quote_id,trim(p_payload->>'item_type'),trim(p_payload->>'description'),
   coalesce(nullif(p_payload->>'quantity','')::numeric,1),(p_payload->>'unit_amount')::numeric,
   nullif(p_payload->>'supplier_id','')::uuid,coalesce(p_payload->'metadata','{}'::jsonb))
  returning * into v;
 else
  update business.quote_items set item_type=trim(p_payload->>'item_type'),description=trim(p_payload->>'description'),
   quantity=coalesce(nullif(p_payload->>'quantity','')::numeric,quantity),
   unit_amount=(p_payload->>'unit_amount')::numeric,
   supplier_id=coalesce(nullif(p_payload->>'supplier_id','')::uuid,supplier_id),
   metadata=coalesce(p_payload->'metadata',metadata)
  where tenant_id=p_tenant_id and quote_id=p_quote_id and id=p_item_id returning * into v;
  if v.id is null then raise exception 'QUOTE_ITEM_NOT_IN_TENANT' using errcode='42501'; end if;
 end if;
 select coalesce(sum(total_amount),0) into v_subtotal from business.quote_items where tenant_id=p_tenant_id and quote_id=p_quote_id;
 update business.quotes set subtotal_amount=v_subtotal,
  total_amount=greatest(v_subtotal-discount_amount+tax_amount+fee_amount,0),
  updated_at=now(),updated_by=auth.uid() where tenant_id=p_tenant_id and id=p_quote_id;
 perform business_private.write_audit(p_tenant_id,'phase13.quote_item.save','quote_item',v.id::text,'success',
  jsonb_build_object('quote_id',p_quote_id));
 return to_jsonb(v);
end $function$;
