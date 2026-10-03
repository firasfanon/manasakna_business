-- Full productization E2E harness. Non-production only.
CREATE OR REPLACE FUNCTION business_private.full_productization_e2e_once()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  t uuid:=gen_random_uuid(); t2 uuid:=gen_random_uuid(); u uuid:=gen_random_uuid();
  org uuid:=gen_random_uuid();
  pkg jsonb; dep jsonb; cust jsonb; leadj jsonb; quotej jsonb; bookj jsonb; trav jsonb;
  supp jsonb; prop jsonb; roomj jsonb; flightj jsonb; transj jsonb; groupj jsonb; supvj jsonb;
  docj jsonb; visaj jsonb; setj jsonb; branchj jsonb; c360 jsonb; b360 jsonb; d360 jsonb;
  cid uuid; lid uuid; qid uuid; bid uuid; trid uuid; pkgid uuid; depid uuid; suppid uuid; propid uuid; gid uuid;
  denied boolean:=false; result jsonb;
begin
  insert into business.tenants(id,slug,display_name) values
    (t,'fp-e2e-'||replace(t::text,'-',''),'Full Productization E2E'),
    (t2,'fp-e2e-'||replace(t2::text,'-',''),'Other Tenant');
  insert into business.memberships(tenant_id,user_id,role,status) values(t,u,'owner','active');
  perform set_config('request.jwt.claim.sub',u::text,true);
  insert into business.organizations(id,tenant_id,name,legal_name)
    values(org,t,'E2E Office','E2E Office Legal');

  pkg:=public.rpc_business_phase13_save_resource_v1(t,'package',null,jsonb_build_object(
    'name','E2E Umrah Package','duration_days',8,'base_price',4850,'currency','SAR','status','active'));
  pkgid:=(pkg->>'id')::uuid;
  dep:=public.rpc_business_phase13_save_resource_v1(t,'departure',null,jsonb_build_object(
    'package_id',pkgid,'start_date',(current_date+30)::text,'end_date',(current_date+38)::text,
    'capacity',20,'status','open'));
  depid:=(dep->>'id')::uuid;

  cust:=public.rpc_business_phase13_save_customer_v1(t,null,jsonb_build_object(
    'full_name','E2E Customer','phone','0500000000','customer_type','individual',
    'preferred_locale','ar','source_channel','synthetic_e2e','tags','[]'::jsonb,
    'communication_consent',false,'data_classification','synthetic','source_provenance','full_productization_e2e'));
  cid:=(cust->>'id')::uuid;
  leadj:=public.rpc_business_phase13_save_lead_v1(t,null,cid,jsonb_build_object(
    'source','synthetic_e2e','expected_travelers',1,'data_classification','synthetic',
    'source_provenance','full_productization_e2e'));
  lid:=(leadj->>'id')::uuid;
  quotej:=public.rpc_business_phase13_save_quote_v1(t,null,lid,jsonb_build_object(
    'quote_code','FP-E2E-Q','currency','SAR','subtotal_amount',4850,'discount_amount',0,
    'tax_amount',0,'fee_amount',0,'departure_id',depid,'package_id',pkgid));
  qid:=(quotej->>'id')::uuid;
  perform public.rpc_business_phase13_update_status_v1(t,'quote',qid,'sent','e2e');
  perform public.rpc_business_phase13_update_status_v1(t,'quote',qid,'accepted','e2e');
  bookj:=public.rpc_business_phase13_save_booking_v1(t,null,qid,jsonb_build_object(
    'booking_code','FP-E2E-B','departure_id',depid,'payment_condition','deposit_required',
    'idempotency_key','fp-e2e-booking'));
  bid:=(bookj->>'id')::uuid;
  trav:=public.rpc_business_phase13_save_traveler_v1(t,bid,null,jsonb_build_object(
    'full_name','E2E Traveler','passport_reference','FP-PASS-001','nationality','PS',
    'data_classification','synthetic','source_provenance','full_productization_e2e'));
  trid:=(trav->>'id')::uuid;

  supp:=public.rpc_business_phase13_save_resource_v1(t,'supplier',null,jsonb_build_object(
    'name','E2E Supplier','supplier_type','hotel','status','active'));
  suppid:=(supp->>'id')::uuid;
  prop:=public.rpc_business_phase13_save_resource_v1(t,'property',null,jsonb_build_object(
    'supplier_id',suppid,'name','E2E Hotel','city','Makkah','status','active'));
  propid:=(prop->>'id')::uuid;
  roomj:=public.rpc_business_phase13_save_resource_v1(t,'accommodation',null,jsonb_build_object(
    'booking_id',bid,'property_id',propid,'traveler_id',trid,'room_label','401',
    'check_in',(current_date+30)::text,'check_out',(current_date+34)::text,'room_type','double',
    'occupancy',1,'status','reserved'));
  flightj:=public.rpc_business_phase13_save_resource_v1(t,'flight',null,jsonb_build_object(
    'booking_id',bid,'flight_number','FP101','origin','AMM','destination','JED',
    'departure_at',(current_date+30)::text||'T08:00:00Z','arrival_at',(current_date+30)::text||'T10:00:00Z',
    'provider_name','E2E Air','segment_type','outbound','ticket_status','ticketed','status','scheduled'));
  transj:=public.rpc_business_phase13_save_resource_v1(t,'transport',null,jsonb_build_object(
    'booking_id',bid,'supplier_id',suppid,'mode','bus','operator_name','E2E Transport',
    'pickup','JED','dropoff','Makkah','scheduled_at',(current_date+30)::text||'T11:00:00Z',
    'vehicle_reference','BUS-01','capacity',40,'status','confirmed'));
  groupj:=public.rpc_business_phase13_save_resource_v1(t,'group',null,jsonb_build_object(
    'departure_id',depid,'code','G01','name','E2E Group','capacity',20,'status','forming'));
  gid:=(groupj->>'id')::uuid;
  supvj:=public.rpc_business_phase13_save_resource_v1(t,'supervisor',null,jsonb_build_object(
    'group_id',gid,'display_name','E2E Supervisor','phone','0500000001','role_title','مشرف','status','assigned'));
  docj:=public.rpc_business_phase13_save_resource_v1(t,'document',null,jsonb_build_object(
    'traveler_id',trid,'document_type','passport','document_reference','FP-DOC-1',
    'document_number','P123','expires_on',(current_date+365)::text,'verification_status','verified'));
  visaj:=public.rpc_business_phase13_save_resource_v1(t,'visa',null,jsonb_build_object(
    'traveler_id',trid,'status','approved','visa_type','umrah','application_reference','FP-VISA-1'));

  setj:=public.rpc_business_product_admin_save_v1(t,'settings',null,jsonb_build_object(
    'brand_name_ar','مكتب الاختبار','brand_name_en','E2E Office','primary_locale','ar',
    'support_email','e2e@example.invalid','support_phone','0500000002'));
  branchj:=public.rpc_business_product_admin_save_v1(t,'branch',null,jsonb_build_object(
    'organization_id',org,'code','HQ','name','الفرع الرئيسي','timezone','Asia/Hebron','is_active',true));

  c360:=public.rpc_business_product_360_v1(t,'customer',cid);
  b360:=public.rpc_business_product_360_v1(t,'booking',bid);
  d360:=public.rpc_business_product_360_v1(t,'departure',depid);

  if jsonb_array_length(public.rpc_business_phase13_list_v1(t,'packages',100)) < 1
     or jsonb_array_length(public.rpc_business_phase13_list_v1(t,'documents',100)) < 1
     or jsonb_array_length(public.rpc_business_phase13_list_v1(t,'visas',100)) < 1
     or jsonb_array_length(public.rpc_business_phase13_list_v1(t,'accommodation',100)) < 1
     or jsonb_array_length(public.rpc_business_phase13_list_v1(t,'flights',100)) < 1
     or jsonb_array_length(public.rpc_business_phase13_list_v1(t,'transport',100)) < 1
     or jsonb_array_length(public.rpc_business_phase13_list_v1(t,'groups',100)) < 1
     or jsonb_array_length(public.rpc_business_phase13_list_v1(t,'supervisors',100)) < 1
  then raise exception 'FULL_PRODUCTIZATION_LIST_COVERAGE_FAILED' using errcode='23514'; end if;

  if jsonb_array_length(c360->'sections'->'الحجوزات') < 1
     or jsonb_array_length(b360->'sections'->'الإقامة والغرف') < 1
     or jsonb_array_length(b360->'sections'->'الطيران') < 1
     or jsonb_array_length(b360->'sections'->'النقل') < 1
     or jsonb_array_length(d360->'sections'->'المجموعات') < 1
     or jsonb_array_length(d360->'sections'->'المشرفون') < 1
  then raise exception 'FULL_PRODUCTIZATION_360_COVERAGE_FAILED' using errcode='23514'; end if;

  begin
    perform public.rpc_business_phase13_save_resource_v1(t2,'package',null,jsonb_build_object(
      'name','DENY','duration_days',1,'base_price',0,'currency','SAR','status','draft'));
  exception when others then
    denied:=true;
  end;
  if not denied then raise exception 'FULL_PRODUCTIZATION_CROSS_TENANT_WRITE_NOT_DENIED' using errcode='42501'; end if;

  result:=jsonb_build_object(
    'pass',true,'tenant_id',t,'package_id',pkgid,'departure_id',depid,'booking_id',bid,
    'traveler_id',trid,'supplier_id',suppid,'property_id',propid,'group_id',gid,
    'document_id',docj->>'id','visa_id',visaj->>'id','rooming_id',roomj->>'id',
    'flight_id',flightj->>'id','transport_id',transj->>'id','supervisor_id',supvj->>'id',
    'settings_ok',setj is not null,'branch_ok',branchj is not null,'cross_tenant_denied',denied);
  raise exception using errcode='P0001',message='FULL_PRODUCTIZATION_E2E_ROLLBACK:'||result::text;
end
$function$
;
revoke all on function business_private.full_productization_e2e_once() from public,anon,authenticated;
