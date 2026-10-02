-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_bounded_quote_booking_crud
-- Version: 20261002184013


create or replace function public.rpc_business_phase13_save_quote_v1(
 p_tenant_id uuid,p_quote_id uuid,p_lead_id uuid,p_payload jsonb
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
 v business.quotes%rowtype;
 v_customer uuid;
 v_snapshot jsonb;
 v_hash text;
 v_currency text;
 v_total numeric;
 v_subtotal numeric;
 v_discount numeric;
 v_tax numeric;
 v_fee numeric;
begin
 perform business_private.assert_scope(p_tenant_id,'quote.manage');
 select customer_id into v_customer from business.leads
 where tenant_id=p_tenant_id and id=p_lead_id;
 if v_customer is null then raise exception 'LEAD_NOT_IN_TENANT' using errcode='42501'; end if;
 v_currency:=coalesce(nullif(trim(p_payload->>'currency'),''),'USD');
 v_subtotal:=coalesce(nullif(p_payload->>'subtotal_amount','')::numeric,0);
 v_discount:=coalesce(nullif(p_payload->>'discount_amount','')::numeric,0);
 v_tax:=coalesce(nullif(p_payload->>'tax_amount','')::numeric,0);
 v_fee:=coalesce(nullif(p_payload->>'fee_amount','')::numeric,0);
 v_total:=coalesce(nullif(p_payload->>'total_amount','')::numeric,v_subtotal-v_discount+v_tax+v_fee);
 if v_total<0 or v_subtotal<0 or v_discount<0 or v_tax<0 or v_fee<0 then
  raise exception 'INVALID_QUOTE_AMOUNT' using errcode='23514';
 end if;
 if nullif(p_payload->>'package_id','') is not null and not exists(
  select 1 from business.packages where tenant_id=p_tenant_id and id=(p_payload->>'package_id')::uuid
 ) then raise exception 'PACKAGE_NOT_IN_TENANT' using errcode='42501'; end if;
 if nullif(p_payload->>'departure_id','') is not null and not exists(
  select 1 from business.departures where tenant_id=p_tenant_id and id=(p_payload->>'departure_id')::uuid
 ) then raise exception 'DEPARTURE_NOT_IN_TENANT' using errcode='42501'; end if;
 v_snapshot:=coalesce(p_payload->'price_snapshot',jsonb_build_object(
  'subtotal_amount',v_subtotal,'discount_amount',v_discount,'tax_amount',v_tax,
  'fee_amount',v_fee,'total_amount',v_total,'currency',v_currency
 ));
 v_hash:=encode(extensions.digest(convert_to(v_snapshot::text,'UTF8'),'sha256'),'hex');
 if p_quote_id is null then
  insert into business.quotes(
   tenant_id,lead_id,customer_id,package_id,departure_id,quote_code,currency,total_amount,
   subtotal_amount,discount_amount,tax_amount,fee_amount,price_snapshot,snapshot_hash,
   valid_until,payment_terms,cancellation_terms,inclusions,exclusions,created_by,updated_by,correlation_id
  ) values(
   p_tenant_id,p_lead_id,v_customer,nullif(p_payload->>'package_id','')::uuid,
   nullif(p_payload->>'departure_id','')::uuid,
   coalesce(nullif(trim(p_payload->>'quote_code'),''),'QT-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))),
   v_currency,v_total,v_subtotal,v_discount,v_tax,v_fee,v_snapshot,v_hash,
   nullif(p_payload->>'valid_until','')::date,nullif(p_payload->>'payment_terms',''),
   nullif(p_payload->>'cancellation_terms',''),coalesce(p_payload->'inclusions','[]'::jsonb),
   coalesce(p_payload->'exclusions','[]'::jsonb),auth.uid(),auth.uid(),gen_random_uuid()
  ) returning * into v;
 else
  update business.quotes set
   package_id=coalesce(nullif(p_payload->>'package_id','')::uuid,package_id),
   departure_id=coalesce(nullif(p_payload->>'departure_id','')::uuid,departure_id),
   currency=v_currency,total_amount=v_total,subtotal_amount=v_subtotal,discount_amount=v_discount,
   tax_amount=v_tax,fee_amount=v_fee,price_snapshot=v_snapshot,snapshot_hash=v_hash,
   valid_until=nullif(p_payload->>'valid_until','')::date,
   payment_terms=coalesce(nullif(p_payload->>'payment_terms',''),payment_terms),
   cancellation_terms=coalesce(nullif(p_payload->>'cancellation_terms',''),cancellation_terms),
   inclusions=coalesce(p_payload->'inclusions',inclusions),exclusions=coalesce(p_payload->'exclusions',exclusions),
   updated_at=now(),updated_by=auth.uid(),version_number=version_number+1
  where tenant_id=p_tenant_id and id=p_quote_id and status='draft'
  returning * into v;
  if v.id is null then raise exception 'QUOTE_NOT_EDITABLE_IN_TENANT' using errcode='42501'; end if;
 end if;
 perform business_private.write_audit(p_tenant_id,'phase13.quote.save','quote',v.id::text,'success',
  jsonb_build_object('lead_id',p_lead_id,'total_amount',v.total_amount,'currency',v.currency));
 return to_jsonb(v);
end $$;
revoke all on function public.rpc_business_phase13_save_quote_v1(uuid,uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_quote_v1(uuid,uuid,uuid,jsonb) to authenticated;

create or replace function public.rpc_business_phase13_save_quote_item_v1(
 p_tenant_id uuid,p_item_id uuid,p_quote_id uuid,p_payload jsonb
) returns jsonb language plpgsql security definer set search_path='' as $$
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
  insert into business.quote_items(tenant_id,quote_id,item_type,description,quantity,unit_amount,total_amount,supplier_id,metadata)
  values(p_tenant_id,p_quote_id,trim(p_payload->>'item_type'),trim(p_payload->>'description'),
   coalesce(nullif(p_payload->>'quantity','')::numeric,1),(p_payload->>'unit_amount')::numeric,
   coalesce(nullif(p_payload->>'quantity','')::numeric,1)*(p_payload->>'unit_amount')::numeric,
   nullif(p_payload->>'supplier_id','')::uuid,coalesce(p_payload->'metadata','{}'::jsonb))
  returning * into v;
 else
  update business.quote_items set item_type=trim(p_payload->>'item_type'),description=trim(p_payload->>'description'),
   quantity=coalesce(nullif(p_payload->>'quantity','')::numeric,quantity),
   unit_amount=(p_payload->>'unit_amount')::numeric,
   total_amount=coalesce(nullif(p_payload->>'quantity','')::numeric,quantity)*(p_payload->>'unit_amount')::numeric,
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
end $$;
revoke all on function public.rpc_business_phase13_save_quote_item_v1(uuid,uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_quote_item_v1(uuid,uuid,uuid,jsonb) to authenticated;

create or replace function public.rpc_business_phase13_save_booking_v1(
 p_tenant_id uuid,p_booking_id uuid,p_quote_id uuid,p_payload jsonb
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
 v business.bookings%rowtype;
 v_quote business.quotes%rowtype;
 v_customer uuid;
 v_departure uuid;
 v_key text;
begin
 perform business_private.assert_scope(p_tenant_id,'booking.manage');
 select * into v_quote from business.quotes where tenant_id=p_tenant_id and id=p_quote_id;
 if v_quote.id is null then raise exception 'QUOTE_NOT_IN_TENANT' using errcode='42501'; end if;
 if p_booking_id is null and v_quote.status<>'accepted' then
  raise exception 'ACCEPTED_QUOTE_REQUIRED' using errcode='23514';
 end if;
 select customer_id into v_customer from business.leads where tenant_id=p_tenant_id and id=v_quote.lead_id;
 v_customer:=coalesce(v_quote.customer_id,v_customer);
 v_departure:=coalesce(nullif(p_payload->>'departure_id','')::uuid,v_quote.departure_id);
 if v_customer is null then raise exception 'CUSTOMER_REQUIRED' using errcode='23514'; end if;
 if v_departure is null or not exists(select 1 from business.departures where tenant_id=p_tenant_id and id=v_departure) then
  raise exception 'DEPARTURE_NOT_IN_TENANT' using errcode='42501';
 end if;
 v_key:=nullif(trim(p_payload->>'idempotency_key'),'');
 if p_booking_id is null and v_key is not null then
  select * into v from business.bookings where tenant_id=p_tenant_id and idempotency_key=v_key;
  if v.id is not null then return to_jsonb(v)||jsonb_build_object('idempotent_replay',true); end if;
 end if;
 if p_booking_id is null then
  insert into business.bookings(
   tenant_id,booking_code,quote_id,departure_id,customer_id,status,branch_id,workflow_stage,
   total_amount,currency,payment_condition,assigned_user_id,external_reference,correlation_id,
   idempotency_key,created_by,updated_by
  ) values(
   p_tenant_id,coalesce(nullif(trim(p_payload->>'booking_code'),''),'UMR-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10))),
   p_quote_id,v_departure,v_customer,'pending',v_quote.branch_id,'booking',
   coalesce(nullif(p_payload->>'total_amount','')::numeric,v_quote.total_amount),
   coalesce(nullif(trim(p_payload->>'currency'),''),v_quote.currency),
   coalesce(nullif(trim(p_payload->>'payment_condition'),''),'deposit_required'),
   nullif(p_payload->>'assigned_user_id','')::uuid,nullif(p_payload->>'external_reference',''),
   gen_random_uuid(),v_key,auth.uid(),auth.uid()
  ) returning * into v;
 else
  update business.bookings set
   departure_id=v_departure,total_amount=coalesce(nullif(p_payload->>'total_amount','')::numeric,total_amount),
   currency=coalesce(nullif(trim(p_payload->>'currency'),''),currency),
   payment_condition=coalesce(nullif(trim(p_payload->>'payment_condition'),''),payment_condition),
   assigned_user_id=coalesce(nullif(p_payload->>'assigned_user_id','')::uuid,assigned_user_id),
   external_reference=coalesce(nullif(p_payload->>'external_reference',''),external_reference),
   updated_at=now(),updated_by=auth.uid(),version=version+1
  where tenant_id=p_tenant_id and id=p_booking_id returning * into v;
  if v.id is null then raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501'; end if;
 end if;
 perform business_private.write_audit(p_tenant_id,'phase13.booking.save','booking',v.id::text,'success',
  jsonb_build_object('quote_id',p_quote_id,'departure_id',v.departure_id,'total_amount',v.total_amount));
 return to_jsonb(v)||jsonb_build_object('idempotent_replay',false);
end $$;
revoke all on function public.rpc_business_phase13_save_booking_v1(uuid,uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_booking_v1(uuid,uuid,uuid,jsonb) to authenticated;
