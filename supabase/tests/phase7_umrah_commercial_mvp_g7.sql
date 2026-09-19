begin;

insert into business.tenants(id,slug,display_name)
values
  ('10000000-0000-4000-8000-0000000000a1','phase7-tenant-a','شركة ألف التجريبية'),
  ('10000000-0000-4000-8000-0000000000b1','phase7-tenant-b','شركة باء التجريبية');

insert into business.memberships(tenant_id,user_id,role,status)
values
  ('10000000-0000-4000-8000-0000000000a1','10000000-0000-4000-8000-0000000000aa','owner','active'),
  ('10000000-0000-4000-8000-0000000000b1','10000000-0000-4000-8000-0000000000bb','owner','active');

set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-0000000000aa',true);

do $$
declare
  v_lead jsonb;
  v_quote jsonb;
  v_pd jsonb;
  v_booking jsonb;
  v_traveler jsonb;
  v_finance jsonb;
  v_context jsonb;
  v_booking_id uuid;
  v_traveler_id uuid;
begin
  v_lead := public.rpc_business_create_lead_v1(
    '10000000-0000-4000-8000-0000000000a1',
    'مسافر ألف التجريبي','+970590000001','a@example.test','synthetic','Phase 7 A'
  );

  v_quote := public.rpc_business_create_quote_v1(
    '10000000-0000-4000-8000-0000000000a1',
    (v_lead->>'lead_id')::uuid,'USD',1200,
    jsonb_build_object(
      'package','Umrah Synthetic A',
      'base',1000,
      'services',jsonb_build_array('hotel','flight','transport'),
      'total',1200
    ),
    current_date + 30
  );

  v_pd := public.rpc_business_create_package_departure_v1(
    '10000000-0000-4000-8000-0000000000a1',
    'برنامج عمرة ألف',7,1200,'USD',
    current_date + 60,current_date + 66,40
  );

  v_booking := public.rpc_business_create_booking_v1(
    '10000000-0000-4000-8000-0000000000a1',
    (v_quote->>'quote_id')::uuid,
    (v_pd->>'departure_id')::uuid
  );
  v_booking_id := (v_booking->>'booking_id')::uuid;

  v_traveler := public.rpc_business_add_traveler_v1(
    '10000000-0000-4000-8000-0000000000a1',
    v_booking_id,'مسافر ألف التجريبي','SYN-A-PASSPORT','PS',
    date '1990-01-01','primary'
  );
  v_traveler_id := (v_traveler->>'traveler_id')::uuid;

  perform public.rpc_business_upsert_document_v1(
    '10000000-0000-4000-8000-0000000000a1',
    v_traveler_id,'passport','SYN-A-DOC','verified'
  );

  perform public.rpc_business_set_visa_v1(
    '10000000-0000-4000-8000-0000000000a1',
    v_traveler_id,'approved','synthetic-regulatory-source','SYN-A-VISA'
  );

  perform public.rpc_business_record_finance_v1(
    '10000000-0000-4000-8000-0000000000a1',
    v_booking_id,'payment',1200,'USD','SYN-A-PAYMENT'
  );

  perform public.rpc_business_configure_synthetic_trip_operations_v1(
    '10000000-0000-4000-8000-0000000000a1',
    v_booking_id
  );

  v_finance := public.rpc_business_booking_finance_v1(
    '10000000-0000-4000-8000-0000000000a1',
    v_booking_id
  );
  if (v_finance->>'balance')::numeric <> 0 then
    raise exception 'TENANT_A_FINANCE_BALANCE_FAILED:%',v_finance;
  end if;

  v_context := public.rpc_business_umrah_journey_context_v1(
    '10000000-0000-4000-8000-0000000000a1',
    v_booking_id
  );

  if v_context->>'journey_type' <> 'umrah'
     or v_context->>'source_authority' <> 'commercialCompany'
     or v_context->>'schema_version' <> 'commercial-umrah-journey-context-v1'
     or jsonb_array_length(v_context->'travelers') <> 1
     or jsonb_array_length(v_context->'flights') <> 1
     or jsonb_array_length(v_context->'transport') <> 1
     or coalesce(v_context->'accommodation'->>'room_label','') <> 'SYN-101'
     or coalesce(v_context->'supervisor'->>'name','') <> 'مشرف تجريبي'
  then
    raise exception 'TENANT_A_JOURNEY_CONTEXT_FAILED:%',v_context;
  end if;

  if jsonb_array_length(
    public.rpc_business_list_bookings_v1(
      '10000000-0000-4000-8000-0000000000a1'
    )
  ) <> 1 then
    raise exception 'TENANT_A_BOOKING_LIST_FAILED';
  end if;
end;
$$;

do $$
begin
  begin
    perform public.rpc_business_list_bookings_v1(
      '10000000-0000-4000-8000-0000000000b1'
    );
    raise exception 'TENANT_A_CROSS_TENANT_ACCESS_ALLOWED';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-0000000000bb',true);

do $$
declare
  v_lead jsonb;
  v_quote jsonb;
  v_pd jsonb;
  v_booking jsonb;
  v_traveler jsonb;
  v_context jsonb;
  v_booking_id uuid;
  v_traveler_id uuid;
begin
  v_lead := public.rpc_business_create_lead_v1(
    '10000000-0000-4000-8000-0000000000b1',
    'مسافر باء التجريبي','+970590000002','b@example.test','synthetic','Phase 7 B'
  );

  v_quote := public.rpc_business_create_quote_v1(
    '10000000-0000-4000-8000-0000000000b1',
    (v_lead->>'lead_id')::uuid,'USD',1500,
    jsonb_build_object('package','Umrah Synthetic B','total',1500),
    current_date + 30
  );

  v_pd := public.rpc_business_create_package_departure_v1(
    '10000000-0000-4000-8000-0000000000b1',
    'برنامج عمرة باء',10,1500,'USD',
    current_date + 70,current_date + 79,50
  );

  v_booking := public.rpc_business_create_booking_v1(
    '10000000-0000-4000-8000-0000000000b1',
    (v_quote->>'quote_id')::uuid,
    (v_pd->>'departure_id')::uuid
  );
  v_booking_id := (v_booking->>'booking_id')::uuid;

  v_traveler := public.rpc_business_add_traveler_v1(
    '10000000-0000-4000-8000-0000000000b1',
    v_booking_id,'مسافر باء التجريبي','SYN-B-PASSPORT','JO',
    date '1988-02-02','primary'
  );
  v_traveler_id := (v_traveler->>'traveler_id')::uuid;

  perform public.rpc_business_upsert_document_v1(
    '10000000-0000-4000-8000-0000000000b1',
    v_traveler_id,'passport','SYN-B-DOC','verified'
  );
  perform public.rpc_business_set_visa_v1(
    '10000000-0000-4000-8000-0000000000b1',
    v_traveler_id,'approved','synthetic-regulatory-source','SYN-B-VISA'
  );
  perform public.rpc_business_record_finance_v1(
    '10000000-0000-4000-8000-0000000000b1',
    v_booking_id,'payment',1500,'USD','SYN-B-PAYMENT'
  );
  perform public.rpc_business_configure_synthetic_trip_operations_v1(
    '10000000-0000-4000-8000-0000000000b1',
    v_booking_id
  );

  v_context := public.rpc_business_umrah_journey_context_v1(
    '10000000-0000-4000-8000-0000000000b1',
    v_booking_id
  );
  if v_context->>'journey_type' <> 'umrah'
     or coalesce(v_context->'organization_context'->>'tenant_id','')
        <> '10000000-0000-4000-8000-0000000000b1'
  then
    raise exception 'TENANT_B_JOURNEY_CONTEXT_FAILED:%',v_context;
  end if;
end;
$$;

do $$
begin
  begin
    perform public.rpc_business_umrah_journey_context_v1(
      '10000000-0000-4000-8000-0000000000a1',
      (select id from business.bookings
       where tenant_id='10000000-0000-4000-8000-0000000000a1' limit 1)
    );
    raise exception 'TENANT_B_CROSS_TENANT_CONTEXT_ALLOWED';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

reset role;

do $$
declare v_quote uuid;
begin
  select id into v_quote from business.quotes
  where tenant_id='10000000-0000-4000-8000-0000000000a1' limit 1;
  begin
    update business.quotes set total_amount=999 where id=v_quote;
    raise exception 'QUOTE_IMMUTABILITY_BROKEN';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

do $$
begin
  if business_private.has_scope(
    '10000000-0000-4000-8000-0000000000a1',
    'hajj.eligibility.manage',
    '10000000-0000-4000-8000-0000000000aa'
  ) then
    raise exception 'HAJJ_SOVEREIGN_SCOPE_ALLOWED';
  end if;
end;
$$;

set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-4000-8000-0000000000aa',true);
do $$
begin
  begin
    perform count(*) from business.bookings;
    raise exception 'DIRECT_TABLE_ACCESS_ALLOWED';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

rollback;
