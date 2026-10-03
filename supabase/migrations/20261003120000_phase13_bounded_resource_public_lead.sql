-- Full-productization bounded CRUD extension.
-- Non-production only. Direct table access remains closed; every resource is
-- allow-listed and checked against tenant-scoped capabilities.
create or replace function public.rpc_business_phase13_save_resource_v1(
  p_tenant_id uuid,
  p_resource text,
  p_id uuid,
  p_payload jsonb
) returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v jsonb;
  v_action text;
begin
  if p_resource in ('package','packages','departure','departures') then
    perform business_private.assert_scope(p_tenant_id,'package.manage');
  elsif p_resource in ('document','documents') then
    perform business_private.assert_scope(p_tenant_id,'document.manage');
  elsif p_resource in ('visa','visas') then
    perform business_private.assert_scope(p_tenant_id,'visa.manage');
  elsif p_resource in ('supplier','suppliers') then
    perform business_private.assert_scope(p_tenant_id,'supplier.manage');
  elsif p_resource in (
    'property','properties','accommodation','rooming',
    'flight','flights','transport','ground_transport',
    'group','groups','supervisor','supervisors'
  ) then
    perform business_private.assert_scope(p_tenant_id,'operations.manage');
  else
    raise exception 'UNSUPPORTED_RESOURCE:%',p_resource using errcode='22023';
  end if;

  if p_resource in ('package','packages') then
    if coalesce(trim(p_payload->>'name'),'')='' then
      raise exception 'PACKAGE_NAME_REQUIRED' using errcode='23514';
    end if;
    if p_id is null then
      insert into business.packages(
        tenant_id,name,duration_days,description,base_price,currency,status
      ) values(
        p_tenant_id,trim(p_payload->>'name'),
        coalesce(nullif(p_payload->>'duration_days','')::int,1),
        nullif(trim(p_payload->>'description'),''),
        coalesce(nullif(p_payload->>'base_price','')::numeric,0),
        upper(coalesce(nullif(trim(p_payload->>'currency'),''),'SAR')),
        coalesce(nullif(trim(p_payload->>'status'),''),'draft')
      ) returning to_jsonb(packages.*) into v;
    else
      update business.packages set
        name=coalesce(nullif(trim(p_payload->>'name'),''),name),
        duration_days=coalesce(nullif(p_payload->>'duration_days','')::int,duration_days),
        description=coalesce(nullif(trim(p_payload->>'description'),''),description),
        base_price=coalesce(nullif(p_payload->>'base_price','')::numeric,base_price),
        currency=coalesce(upper(nullif(trim(p_payload->>'currency'),'')),currency),
        status=coalesce(nullif(trim(p_payload->>'status'),''),status),
        updated_at=now()
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(packages.*) into v;
    end if;
    v_action:='package.save';

  elsif p_resource in ('departure','departures') then
    if p_id is null then
      insert into business.departures(
        tenant_id,package_id,start_date,end_date,capacity,status
      ) values(
        p_tenant_id,(p_payload->>'package_id')::uuid,
        (p_payload->>'start_date')::date,(p_payload->>'end_date')::date,
        coalesce(nullif(p_payload->>'capacity','')::int,1),
        coalesce(nullif(trim(p_payload->>'status'),''),'planned')
      ) returning to_jsonb(departures.*) into v;
    else
      update business.departures set
        package_id=coalesce(nullif(p_payload->>'package_id','')::uuid,package_id),
        start_date=coalesce(nullif(p_payload->>'start_date','')::date,start_date),
        end_date=coalesce(nullif(p_payload->>'end_date','')::date,end_date),
        capacity=coalesce(nullif(p_payload->>'capacity','')::int,capacity),
        status=coalesce(nullif(trim(p_payload->>'status'),''),status),
        updated_at=now()
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(departures.*) into v;
    end if;
    v_action:='departure.save';

  elsif p_resource in ('document','documents') then
    if p_id is null then
      insert into business.traveler_documents(
        tenant_id,traveler_id,document_type,document_reference,
        document_number,issued_on,expires_on,issuing_country,
        verification_status,rejection_reason,source_provenance
      ) values(
        p_tenant_id,(p_payload->>'traveler_id')::uuid,
        p_payload->>'document_type',p_payload->>'document_reference',
        nullif(p_payload->>'document_number',''),
        nullif(p_payload->>'issued_on','')::date,
        nullif(p_payload->>'expires_on','')::date,
        nullif(p_payload->>'issuing_country',''),
        coalesce(nullif(p_payload->>'verification_status',''),'pending'),
        nullif(p_payload->>'rejection_reason',''),'phase13_operator_console'
      ) returning to_jsonb(traveler_documents.*) into v;
    else
      update business.traveler_documents set
        traveler_id=coalesce(nullif(p_payload->>'traveler_id','')::uuid,traveler_id),
        document_type=coalesce(nullif(p_payload->>'document_type',''),document_type),
        document_reference=coalesce(nullif(p_payload->>'document_reference',''),document_reference),
        document_number=coalesce(nullif(p_payload->>'document_number',''),document_number),
        issued_on=coalesce(nullif(p_payload->>'issued_on','')::date,issued_on),
        expires_on=coalesce(nullif(p_payload->>'expires_on','')::date,expires_on),
        issuing_country=coalesce(nullif(p_payload->>'issuing_country',''),issuing_country),
        verification_status=coalesce(nullif(p_payload->>'verification_status',''),verification_status),
        rejection_reason=coalesce(nullif(p_payload->>'rejection_reason',''),rejection_reason),
        updated_at=now()
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(traveler_documents.*) into v;
    end if;
    v_action:='document.save';

  elsif p_resource in ('visa','visas') then
    if p_id is null then
      insert into business.visa_cases(
        tenant_id,traveler_id,status,visa_type,application_reference,
        authority_source,external_reference,expires_on,rejection_reason,
        source_provenance
      ) values(
        p_tenant_id,(p_payload->>'traveler_id')::uuid,
        coalesce(nullif(p_payload->>'status',''),'not_started'),
        coalesce(nullif(p_payload->>'visa_type',''),'umrah'),
        nullif(p_payload->>'application_reference',''),
        nullif(p_payload->>'authority_source',''),
        nullif(p_payload->>'external_reference',''),
        nullif(p_payload->>'expires_on','')::date,
        nullif(p_payload->>'rejection_reason',''),'phase13_operator_console'
      ) returning to_jsonb(visa_cases.*) into v;
    else
      update business.visa_cases set
        traveler_id=coalesce(nullif(p_payload->>'traveler_id','')::uuid,traveler_id),
        status=coalesce(nullif(p_payload->>'status',''),status),
        visa_type=coalesce(nullif(p_payload->>'visa_type',''),visa_type),
        application_reference=coalesce(nullif(p_payload->>'application_reference',''),application_reference),
        authority_source=coalesce(nullif(p_payload->>'authority_source',''),authority_source),
        external_reference=coalesce(nullif(p_payload->>'external_reference',''),external_reference),
        expires_on=coalesce(nullif(p_payload->>'expires_on','')::date,expires_on),
        rejection_reason=coalesce(nullif(p_payload->>'rejection_reason',''),rejection_reason),
        updated_at=now()
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(visa_cases.*) into v;
    end if;
    v_action:='visa.save';

  elsif p_resource in ('supplier','suppliers') then
    if p_id is null then
      insert into business.suppliers(
        tenant_id,name,supplier_type,contact_name,phone,email,country,city,
        payment_terms,notes,status,data_classification
      ) values(
        p_tenant_id,p_payload->>'name',p_payload->>'supplier_type',
        nullif(p_payload->>'contact_name',''),nullif(p_payload->>'phone',''),
        nullif(p_payload->>'email',''),nullif(p_payload->>'country',''),
        nullif(p_payload->>'city',''),nullif(p_payload->>'payment_terms',''),
        nullif(p_payload->>'notes',''),
        coalesce(nullif(p_payload->>'status',''),'active'),'synthetic'
      ) returning to_jsonb(suppliers.*) into v;
    else
      update business.suppliers set
        name=coalesce(nullif(p_payload->>'name',''),name),
        supplier_type=coalesce(nullif(p_payload->>'supplier_type',''),supplier_type),
        contact_name=coalesce(nullif(p_payload->>'contact_name',''),contact_name),
        phone=coalesce(nullif(p_payload->>'phone',''),phone),
        email=coalesce(nullif(p_payload->>'email',''),email),
        country=coalesce(nullif(p_payload->>'country',''),country),
        city=coalesce(nullif(p_payload->>'city',''),city),
        payment_terms=coalesce(nullif(p_payload->>'payment_terms',''),payment_terms),
        notes=coalesce(nullif(p_payload->>'notes',''),notes),
        status=coalesce(nullif(p_payload->>'status',''),status),
        updated_at=now()
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(suppliers.*) into v;
    end if;
    v_action:='supplier.save';

  elsif p_resource in ('property','properties') then
    if p_id is null then
      insert into business.properties(
        tenant_id,supplier_id,name,city,address,star_rating,
        distance_to_haram_m,contact_phone,status,source_provenance
      ) values(
        p_tenant_id,nullif(p_payload->>'supplier_id','')::uuid,
        p_payload->>'name',p_payload->>'city',
        nullif(p_payload->>'address',''),
        nullif(p_payload->>'star_rating','')::numeric,
        nullif(p_payload->>'distance_to_haram_m','')::int,
        nullif(p_payload->>'contact_phone',''),
        coalesce(nullif(p_payload->>'status',''),'active'),
        'phase13_operator_console'
      ) returning to_jsonb(properties.*) into v;
    else
      update business.properties set
        supplier_id=coalesce(nullif(p_payload->>'supplier_id','')::uuid,supplier_id),
        name=coalesce(nullif(p_payload->>'name',''),name),
        city=coalesce(nullif(p_payload->>'city',''),city),
        address=coalesce(nullif(p_payload->>'address',''),address),
        star_rating=coalesce(nullif(p_payload->>'star_rating','')::numeric,star_rating),
        distance_to_haram_m=coalesce(nullif(p_payload->>'distance_to_haram_m','')::int,distance_to_haram_m),
        contact_phone=coalesce(nullif(p_payload->>'contact_phone',''),contact_phone),
        status=coalesce(nullif(p_payload->>'status',''),status)
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(properties.*) into v;
    end if;
    v_action:='property.save';

  elsif p_resource in ('accommodation','rooming') then
    if p_id is null then
      insert into business.rooming_assignments(
        tenant_id,booking_id,property_id,traveler_id,room_label,
        check_in,check_out,room_type,occupancy,status,notes
      ) values(
        p_tenant_id,(p_payload->>'booking_id')::uuid,
        (p_payload->>'property_id')::uuid,
        nullif(p_payload->>'traveler_id','')::uuid,
        p_payload->>'room_label',(p_payload->>'check_in')::date,
        (p_payload->>'check_out')::date,nullif(p_payload->>'room_type',''),
        nullif(p_payload->>'occupancy','')::int,
        coalesce(nullif(p_payload->>'status',''),'reserved'),
        nullif(p_payload->>'notes','')
      ) returning to_jsonb(rooming_assignments.*) into v;
    else
      update business.rooming_assignments set
        booking_id=coalesce(nullif(p_payload->>'booking_id','')::uuid,booking_id),
        property_id=coalesce(nullif(p_payload->>'property_id','')::uuid,property_id),
        traveler_id=coalesce(nullif(p_payload->>'traveler_id','')::uuid,traveler_id),
        room_label=coalesce(nullif(p_payload->>'room_label',''),room_label),
        check_in=coalesce(nullif(p_payload->>'check_in','')::date,check_in),
        check_out=coalesce(nullif(p_payload->>'check_out','')::date,check_out),
        room_type=coalesce(nullif(p_payload->>'room_type',''),room_type),
        occupancy=coalesce(nullif(p_payload->>'occupancy','')::int,occupancy),
        status=coalesce(nullif(p_payload->>'status',''),status),
        notes=coalesce(nullif(p_payload->>'notes',''),notes)
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(rooming_assignments.*) into v;
    end if;
    v_action:='rooming.save';

  elsif p_resource in ('flight','flights') then
    if p_id is null then
      insert into business.flights(
        tenant_id,booking_id,flight_number,origin,destination,departure_at,
        arrival_at,provider_name,segment_type,airline_code,booking_reference,
        ticket_status,cabin_class,baggage_allowance,status,source_provenance
      ) values(
        p_tenant_id,(p_payload->>'booking_id')::uuid,p_payload->>'flight_number',
        p_payload->>'origin',p_payload->>'destination',
        (p_payload->>'departure_at')::timestamptz,
        (p_payload->>'arrival_at')::timestamptz,
        nullif(p_payload->>'provider_name',''),
        coalesce(nullif(p_payload->>'segment_type',''),'outbound'),
        nullif(p_payload->>'airline_code',''),
        nullif(p_payload->>'booking_reference',''),
        coalesce(nullif(p_payload->>'ticket_status',''),'planned'),
        nullif(p_payload->>'cabin_class',''),
        nullif(p_payload->>'baggage_allowance',''),
        coalesce(nullif(p_payload->>'status',''),'scheduled'),
        'phase13_operator_console'
      ) returning to_jsonb(flights.*) into v;
    else
      update business.flights set
        booking_id=coalesce(nullif(p_payload->>'booking_id','')::uuid,booking_id),
        flight_number=coalesce(nullif(p_payload->>'flight_number',''),flight_number),
        origin=coalesce(nullif(p_payload->>'origin',''),origin),
        destination=coalesce(nullif(p_payload->>'destination',''),destination),
        departure_at=coalesce(nullif(p_payload->>'departure_at','')::timestamptz,departure_at),
        arrival_at=coalesce(nullif(p_payload->>'arrival_at','')::timestamptz,arrival_at),
        provider_name=coalesce(nullif(p_payload->>'provider_name',''),provider_name),
        segment_type=coalesce(nullif(p_payload->>'segment_type',''),segment_type),
        airline_code=coalesce(nullif(p_payload->>'airline_code',''),airline_code),
        booking_reference=coalesce(nullif(p_payload->>'booking_reference',''),booking_reference),
        ticket_status=coalesce(nullif(p_payload->>'ticket_status',''),ticket_status),
        cabin_class=coalesce(nullif(p_payload->>'cabin_class',''),cabin_class),
        baggage_allowance=coalesce(nullif(p_payload->>'baggage_allowance',''),baggage_allowance),
        status=coalesce(nullif(p_payload->>'status',''),status)
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(flights.*) into v;
    end if;
    v_action:='flight.save';

  elsif p_resource in ('transport','ground_transport') then
    if p_id is null then
      insert into business.ground_transports(
        tenant_id,booking_id,supplier_id,mode,operator_name,pickup,dropoff,
        scheduled_at,vehicle_reference,driver_name,driver_phone,capacity,
        status,source_provenance
      ) values(
        p_tenant_id,(p_payload->>'booking_id')::uuid,
        nullif(p_payload->>'supplier_id','')::uuid,p_payload->>'mode',
        nullif(p_payload->>'operator_name',''),p_payload->>'pickup',
        p_payload->>'dropoff',(p_payload->>'scheduled_at')::timestamptz,
        nullif(p_payload->>'vehicle_reference',''),
        nullif(p_payload->>'driver_name',''),nullif(p_payload->>'driver_phone',''),
        nullif(p_payload->>'capacity','')::int,
        coalesce(nullif(p_payload->>'status',''),'planned'),
        'phase13_operator_console'
      ) returning to_jsonb(ground_transports.*) into v;
    else
      update business.ground_transports set
        booking_id=coalesce(nullif(p_payload->>'booking_id','')::uuid,booking_id),
        supplier_id=coalesce(nullif(p_payload->>'supplier_id','')::uuid,supplier_id),
        mode=coalesce(nullif(p_payload->>'mode',''),mode),
        operator_name=coalesce(nullif(p_payload->>'operator_name',''),operator_name),
        pickup=coalesce(nullif(p_payload->>'pickup',''),pickup),
        dropoff=coalesce(nullif(p_payload->>'dropoff',''),dropoff),
        scheduled_at=coalesce(nullif(p_payload->>'scheduled_at','')::timestamptz,scheduled_at),
        vehicle_reference=coalesce(nullif(p_payload->>'vehicle_reference',''),vehicle_reference),
        driver_name=coalesce(nullif(p_payload->>'driver_name',''),driver_name),
        driver_phone=coalesce(nullif(p_payload->>'driver_phone',''),driver_phone),
        capacity=coalesce(nullif(p_payload->>'capacity','')::int,capacity),
        status=coalesce(nullif(p_payload->>'status',''),status)
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(ground_transports.*) into v;
    end if;
    v_action:='transport.save';

  elsif p_resource in ('group','groups') then
    if p_id is null then
      insert into business.trip_groups(
        tenant_id,departure_id,code,name,capacity,status
      ) values(
        p_tenant_id,(p_payload->>'departure_id')::uuid,p_payload->>'code',
        p_payload->>'name',nullif(p_payload->>'capacity','')::int,
        coalesce(nullif(p_payload->>'status',''),'forming')
      ) returning to_jsonb(trip_groups.*) into v;
    else
      update business.trip_groups set
        departure_id=coalesce(nullif(p_payload->>'departure_id','')::uuid,departure_id),
        code=coalesce(nullif(p_payload->>'code',''),code),
        name=coalesce(nullif(p_payload->>'name',''),name),
        capacity=coalesce(nullif(p_payload->>'capacity','')::int,capacity),
        status=coalesce(nullif(p_payload->>'status',''),status)
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(trip_groups.*) into v;
    end if;
    v_action:='group.save';

  elsif p_resource in ('supervisor','supervisors') then
    if p_id is null then
      insert into business.supervisors(
        tenant_id,group_id,display_name,phone,email,role_title,status
      ) values(
        p_tenant_id,(p_payload->>'group_id')::uuid,p_payload->>'display_name',
        nullif(p_payload->>'phone',''),nullif(p_payload->>'email',''),
        nullif(p_payload->>'role_title',''),
        coalesce(nullif(p_payload->>'status',''),'assigned')
      ) returning to_jsonb(supervisors.*) into v;
    else
      update business.supervisors set
        group_id=coalesce(nullif(p_payload->>'group_id','')::uuid,group_id),
        display_name=coalesce(nullif(p_payload->>'display_name',''),display_name),
        phone=coalesce(nullif(p_payload->>'phone',''),phone),
        email=coalesce(nullif(p_payload->>'email',''),email),
        role_title=coalesce(nullif(p_payload->>'role_title',''),role_title),
        status=coalesce(nullif(p_payload->>'status',''),status)
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(supervisors.*) into v;
    end if;
    v_action:='supervisor.save';
  end if;

  if v is null then
    raise exception 'RESOURCE_NOT_IN_TENANT' using errcode='42501';
  end if;
  perform business_private.write_audit(
    p_tenant_id,v_action,p_resource,coalesce(v->>'id',p_id::text),
    'success',jsonb_build_object('source','full_productization_ui')
  );
  return v;
end
$$;

revoke all on function public.rpc_business_phase13_save_resource_v1(
  uuid,text,uuid,jsonb
) from public,anon;
grant execute on function public.rpc_business_phase13_save_resource_v1(
  uuid,text,uuid,jsonb
) to authenticated;

create or replace function public.rpc_business_phase13_list_v1(
  p_tenant_id uuid,p_resource text,p_limit integer default 100
) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare v jsonb;
begin
  if p_limit<1 or p_limit>500 then
    raise exception 'INVALID_LIMIT' using errcode='22023';
  end if;
  if p_resource='customers' then
    perform business_private.assert_scope(p_tenant_id,'crm.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.customers where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='leads' then
    perform business_private.assert_scope(p_tenant_id,'crm.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.leads where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='quotes' then
    perform business_private.assert_scope(p_tenant_id,'quote.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.quotes where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='packages' then
    perform business_private.assert_scope(p_tenant_id,'package.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.packages where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='departures' then
    perform business_private.assert_scope(p_tenant_id,'package.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.departures where tenant_id=p_tenant_id order by start_date desc limit p_limit)x;
  elsif p_resource='bookings' then
    perform business_private.assert_scope(p_tenant_id,'booking.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.bookings where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='travelers' then
    perform business_private.assert_scope(p_tenant_id,'traveler.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.travelers where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='documents' then
    perform business_private.assert_scope(p_tenant_id,'document.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.traveler_documents where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='visas' then
    perform business_private.assert_scope(p_tenant_id,'visa.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.visa_cases where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='finance' then
    perform business_private.assert_scope(p_tenant_id,'finance.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.finance_entries where tenant_id=p_tenant_id order by occurred_at desc limit p_limit)x;
  elsif p_resource='suppliers' then
    perform business_private.assert_scope(p_tenant_id,'supplier.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.suppliers where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='properties' then
    perform business_private.assert_scope(p_tenant_id,'operations.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.properties where tenant_id=p_tenant_id order by created_at desc limit p_limit)x;
  elsif p_resource='accommodation' then
    perform business_private.assert_scope(p_tenant_id,'operations.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.rooming_assignments where tenant_id=p_tenant_id order by created_at desc limit p_limit)x;
  elsif p_resource='flights' then
    perform business_private.assert_scope(p_tenant_id,'operations.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.flights where tenant_id=p_tenant_id order by departure_at desc limit p_limit)x;
  elsif p_resource='transport' then
    perform business_private.assert_scope(p_tenant_id,'operations.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.ground_transports where tenant_id=p_tenant_id order by scheduled_at desc limit p_limit)x;
  elsif p_resource='groups' then
    perform business_private.assert_scope(p_tenant_id,'operations.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.trip_groups where tenant_id=p_tenant_id order by created_at desc limit p_limit)x;
  elsif p_resource='supervisors' then
    perform business_private.assert_scope(p_tenant_id,'operations.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.supervisors where tenant_id=p_tenant_id order by created_at desc limit p_limit)x;
  elsif p_resource='tasks' then
    perform business_private.assert_scope(p_tenant_id,'operations.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.operational_tasks where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  elsif p_resource='support' then
    perform business_private.assert_scope(p_tenant_id,'support.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (select * from business.support_cases where tenant_id=p_tenant_id order by updated_at desc limit p_limit)x;
  else
    raise exception 'UNSUPPORTED_RESOURCE:%',p_resource using errcode='22023';
  end if;
  return v;
end
$$;
revoke all on function public.rpc_business_phase13_list_v1(
  uuid,text,integer
) from public,anon;
grant execute on function public.rpc_business_phase13_list_v1(
  uuid,text,integer
) to authenticated;

-- Deliberately public, bounded lead capture. It only creates synthetic
-- non-production customer/lead records and performs no privileged read.
create or replace function public.rpc_business_public_lead_capture_v1(
  p_tenant_id uuid,p_payload jsonb
) returns jsonb
language plpgsql security definer set search_path='' as $$
declare
  c business.customers%rowtype;
  l business.leads%rowtype;
begin
  if coalesce(trim(p_payload->>'full_name'),'')='' or
     coalesce(trim(p_payload->>'phone'),'')='' then
    raise exception 'PUBLIC_LEAD_NAME_AND_PHONE_REQUIRED' using errcode='23514';
  end if;
  if length(trim(p_payload->>'full_name'))>160 or
     length(trim(p_payload->>'phone'))>40 or
     length(coalesce(p_payload->>'message',''))>2000 then
    raise exception 'PUBLIC_LEAD_INPUT_TOO_LONG' using errcode='22023';
  end if;
  if not exists(
    select 1 from business.tenants where id=p_tenant_id and status='active'
  ) then
    raise exception 'TENANT_NOT_FOUND' using errcode='22023';
  end if;
  insert into business.customers(
    tenant_id,full_name,phone,email,data_classification,source_channel
  ) values(
    p_tenant_id,trim(p_payload->>'full_name'),trim(p_payload->>'phone'),
    nullif(trim(p_payload->>'email'),''),
    'synthetic','public_web'
  ) returning * into c;

  insert into business.leads(
    tenant_id,customer_id,source,status,notes,data_classification
  ) values(
    p_tenant_id,c.id,'public_web','new',
    nullif(trim(p_payload->>'message'),''),
    'synthetic'
  ) returning * into l;

  perform business_private.write_audit(
    p_tenant_id,'public.lead.capture','lead',l.id::text,'success',
    jsonb_build_object('data_classification','synthetic')
  );
  return jsonb_build_object('customer',to_jsonb(c),'lead',to_jsonb(l));
end
$$;

revoke all on function public.rpc_business_public_lead_capture_v1(
  uuid,jsonb
) from public;
grant execute on function public.rpc_business_public_lead_capture_v1(
  uuid,jsonb
) to anon,authenticated;
