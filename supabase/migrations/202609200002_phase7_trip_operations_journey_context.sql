begin;

create table business.suppliers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  name text not null,
  supplier_type text not null check (supplier_type in ('hotel','flight','transport','visa','other')),
  status text not null default 'active' check (status in ('active','inactive')),
  data_classification text not null default 'synthetic' check (data_classification='synthetic'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id,id)
);

create table business.supplier_contracts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  supplier_id uuid not null,
  contract_reference text not null,
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  valid_from date, valid_to date,
  terms jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,supplier_id) references business.suppliers(tenant_id,id) on delete cascade
);

create table business.properties (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  supplier_id uuid,
  name text not null,
  city text not null,
  source_provenance text not null default 'commercial_company',
  created_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,supplier_id) references business.suppliers(tenant_id,id) on delete set null
);

create table business.rooming_assignments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_id uuid not null,
  property_id uuid not null,
  room_label text not null,
  check_in date not null,
  check_out date not null,
  created_at timestamptz not null default now(),
  unique (tenant_id,id),
  unique (tenant_id,booking_id),
  check (check_out >= check_in),
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade,
  foreign key (tenant_id,property_id) references business.properties(tenant_id,id) on delete restrict
);

create table business.flights (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_id uuid not null,
  flight_number text not null,
  origin text not null,
  destination text not null,
  departure_at timestamptz not null,
  arrival_at timestamptz not null,
  provider_name text,
  source_provenance text not null default 'commercial_company',
  created_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade
);

create table business.ground_transports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_id uuid not null,
  mode text not null check (mode in ('bus','van','car','train','other')),
  operator_name text,
  pickup text not null,
  dropoff text not null,
  scheduled_at timestamptz not null,
  source_provenance text not null default 'commercial_company',
  created_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade
);

create table business.trip_groups (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  departure_id uuid not null,
  code text not null,
  name text not null,
  created_at timestamptz not null default now(),
  unique (tenant_id,id),
  unique (tenant_id,code),
  foreign key (tenant_id,departure_id) references business.departures(tenant_id,id) on delete cascade
);

create table business.group_booking_assignments (
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  group_id uuid not null,
  booking_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (tenant_id,group_id,booking_id),
  foreign key (tenant_id,group_id) references business.trip_groups(tenant_id,id) on delete cascade,
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade
);

create table business.supervisors (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  group_id uuid not null,
  display_name text not null,
  phone text,
  created_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,group_id) references business.trip_groups(tenant_id,id) on delete cascade
);

create table business.operational_tasks (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_id uuid not null,
  title text not null,
  status text not null default 'open' check (status in ('open','in_progress','done','cancelled')),
  due_at timestamptz,
  assigned_user_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade
);

create table business.support_cases (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_id uuid not null,
  traveler_id uuid,
  category text not null,
  summary text not null,
  status text not null default 'open' check (status in ('open','pending','resolved','closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade,
  foreign key (tenant_id,traveler_id) references business.travelers(tenant_id,id) on delete set null
);

create table business.supplier_payables (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  supplier_id uuid not null,
  booking_id uuid not null,
  amount numeric(14,2) not null check (amount >= 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  status text not null default 'open' check (status in ('open','approved','paid','cancelled')),
  created_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,supplier_id) references business.suppliers(tenant_id,id) on delete restrict,
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade
);

create index rooming_booking_idx on business.rooming_assignments(tenant_id,booking_id);
create index flights_booking_idx on business.flights(tenant_id,booking_id,departure_at);
create index transports_booking_idx on business.ground_transports(tenant_id,booking_id,scheduled_at);
create index group_booking_idx on business.group_booking_assignments(tenant_id,booking_id);
create index support_booking_idx on business.support_cases(tenant_id,booking_id,status);
create index tasks_booking_idx on business.operational_tasks(tenant_id,booking_id,status);

create trigger suppliers_touch_updated_at before update on business.suppliers
for each row execute function business_private.touch_updated_at();
create trigger operational_tasks_touch_updated_at before update on business.operational_tasks
for each row execute function business_private.touch_updated_at();
create trigger support_cases_touch_updated_at before update on business.support_cases
for each row execute function business_private.touch_updated_at();

alter table business.suppliers enable row level security;
alter table business.suppliers force row level security;
alter table business.supplier_contracts enable row level security;
alter table business.supplier_contracts force row level security;
alter table business.properties enable row level security;
alter table business.properties force row level security;
alter table business.rooming_assignments enable row level security;
alter table business.rooming_assignments force row level security;
alter table business.flights enable row level security;
alter table business.flights force row level security;
alter table business.ground_transports enable row level security;
alter table business.ground_transports force row level security;
alter table business.trip_groups enable row level security;
alter table business.trip_groups force row level security;
alter table business.group_booking_assignments enable row level security;
alter table business.group_booking_assignments force row level security;
alter table business.supervisors enable row level security;
alter table business.supervisors force row level security;
alter table business.operational_tasks enable row level security;
alter table business.operational_tasks force row level security;
alter table business.support_cases enable row level security;
alter table business.support_cases force row level security;
alter table business.supplier_payables enable row level security;
alter table business.supplier_payables force row level security;

revoke all on all tables in schema business from public,anon,authenticated;
revoke all on all sequences in schema business from public,anon,authenticated;

create or replace function public.rpc_business_configure_synthetic_trip_operations_v1(
  p_tenant_id uuid,
  p_booking_id uuid
) returns jsonb language plpgsql security definer set search_path='' as $$
declare
  v_departure_id uuid;
  v_start date;
  v_end date;
  v_traveler_id uuid;
  v_supplier_id uuid;
  v_property_id uuid;
  v_group_id uuid;
  v_supervisor_id uuid;
  v_rooming_id uuid;
  v_flight_id uuid;
  v_transport_id uuid;
  v_support_id uuid;
begin
  perform business_private.assert_scope(p_tenant_id,'operations.manage');

  select b.departure_id,d.start_date,d.end_date
  into v_departure_id,v_start,v_end
  from business.bookings b
  join business.departures d
    on d.tenant_id=b.tenant_id and d.id=b.departure_id
  where b.tenant_id=p_tenant_id and b.id=p_booking_id;

  if v_departure_id is null then
    raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501';
  end if;

  select traveler_id into v_traveler_id
  from business.booking_travelers
  where tenant_id=p_tenant_id and booking_id=p_booking_id
  order by created_at limit 1;

  insert into business.suppliers(
    tenant_id,name,supplier_type,status,data_classification
  ) values(
    p_tenant_id,'Synthetic Makkah Hospitality','hotel','active','synthetic'
  ) returning id into v_supplier_id;

  insert into business.supplier_contracts(
    tenant_id,supplier_id,contract_reference,currency,valid_from,valid_to,terms
  ) values(
    p_tenant_id,v_supplier_id,'SYN-HOTEL-'||substr(v_supplier_id::text,1,8),
    'USD',v_start,v_end,jsonb_build_object('synthetic',true,'rate_type','room')
  );

  insert into business.properties(
    tenant_id,supplier_id,name,city,source_provenance
  ) values(
    p_tenant_id,v_supplier_id,'Synthetic Haram Hotel','Makkah','commercial_company'
  ) returning id into v_property_id;

  insert into business.rooming_assignments(
    tenant_id,booking_id,property_id,room_label,check_in,check_out
  ) values(
    p_tenant_id,p_booking_id,v_property_id,'SYN-101',v_start,v_end
  ) returning id into v_rooming_id;

  insert into business.flights(
    tenant_id,booking_id,flight_number,origin,destination,
    departure_at,arrival_at,provider_name,source_provenance
  ) values(
    p_tenant_id,p_booking_id,'SYN700','AMM','JED',
    (v_start::timestamp + time '06:00') at time zone 'Asia/Amman',
    (v_start::timestamp + time '08:30') at time zone 'Asia/Riyadh',
    'Synthetic Air','commercial_company'
  ) returning id into v_flight_id;

  insert into business.ground_transports(
    tenant_id,booking_id,mode,operator_name,pickup,dropoff,
    scheduled_at,source_provenance
  ) values(
    p_tenant_id,p_booking_id,'bus','Synthetic Transport',
    'JED Airport','Makkah Hotel',
    (v_start::timestamp + time '10:00') at time zone 'Asia/Riyadh',
    'commercial_company'
  ) returning id into v_transport_id;

  insert into business.trip_groups(
    tenant_id,departure_id,code,name
  ) values(
    p_tenant_id,v_departure_id,
    'G-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),
    'مجموعة العمرة التجريبية'
  ) returning id into v_group_id;

  insert into business.group_booking_assignments(
    tenant_id,group_id,booking_id
  ) values(p_tenant_id,v_group_id,p_booking_id);

  insert into business.supervisors(
    tenant_id,group_id,display_name,phone
  ) values(
    p_tenant_id,v_group_id,'مشرف تجريبي','+970000000000'
  ) returning id into v_supervisor_id;

  insert into business.operational_tasks(
    tenant_id,booking_id,title,status,due_at
  ) values(
    p_tenant_id,p_booking_id,'مراجعة جاهزية الرحلة','open',
    (v_start::timestamp - interval '2 days') at time zone 'Asia/Hebron'
  );

  insert into business.support_cases(
    tenant_id,booking_id,traveler_id,category,summary,status
  ) values(
    p_tenant_id,p_booking_id,v_traveler_id,'pre_trip','حالة دعم تجريبية','open'
  ) returning id into v_support_id;

  insert into business.supplier_payables(
    tenant_id,supplier_id,booking_id,amount,currency,status
  ) values(
    p_tenant_id,v_supplier_id,p_booking_id,450,'USD','open'
  );

  perform business_private.write_audit(
    p_tenant_id,'trip.operations.configure','booking',p_booking_id::text,
    'success',jsonb_build_object('synthetic',true,'group_id',v_group_id)
  );

  return jsonb_build_object(
    'property_id',v_property_id,
    'rooming_id',v_rooming_id,
    'flight_id',v_flight_id,
    'transport_id',v_transport_id,
    'group_id',v_group_id,
    'supervisor_id',v_supervisor_id,
    'support_case_id',v_support_id
  );
end;
$$;

create or replace function public.rpc_business_pipeline_summary_v1(
  p_tenant_id uuid
) returns jsonb language plpgsql stable security definer set search_path='' as $$
begin
  perform business_private.assert_scope(p_tenant_id,'booking.read');

  return jsonb_build_object(
    'leads',(select count(*) from business.leads where tenant_id=p_tenant_id),
    'quotes',(select count(*) from business.quotes where tenant_id=p_tenant_id),
    'bookings',(select count(*) from business.bookings where tenant_id=p_tenant_id),
    'travelers',(select count(*) from business.travelers where tenant_id=p_tenant_id),
    'departures',(select count(*) from business.departures where tenant_id=p_tenant_id),
    'open_support',(
      select count(*) from business.support_cases
      where tenant_id=p_tenant_id and status in ('open','pending')
    ),
    'open_tasks',(
      select count(*) from business.operational_tasks
      where tenant_id=p_tenant_id and status in ('open','in_progress')
    )
  );
end;
$$;

create or replace function public.rpc_business_umrah_journey_context_v1(
  p_tenant_id uuid,
  p_booking_id uuid
) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare
  v_result jsonb;
begin
  perform business_private.assert_scope(p_tenant_id,'journey.read');

  if not exists(
    select 1 from business.bookings
    where tenant_id=p_tenant_id and id=p_booking_id
  ) then
    raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501';
  end if;

  select jsonb_build_object(
    'schema_version','commercial-umrah-journey-context-v1',
    'journey_id',b.id,
    'journey_type','umrah',
    'source_authority','commercialCompany',
    'authority_provenance',jsonb_build_object(
      'source_authority','commercialCompany',
      'source_id','MANASAKNA_BUSINESS',
      'is_authoritative',true,
      'observed_at',now()
    ),
    'organization_context',jsonb_build_object(
      'tenant_id',b.tenant_id,
      'tenant_name',t.display_name
    ),
    'booking',jsonb_build_object(
      'booking_code',b.booking_code,
      'status',b.status,
      'booked_at',b.booked_at
    ),
    'package',jsonb_build_object(
      'name',p.name,
      'duration_days',p.duration_days,
      'currency',p.currency
    ),
    'departure',jsonb_build_object(
      'start_date',d.start_date,
      'end_date',d.end_date,
      'status',d.status
    ),
    'travelers',coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id',tr.id,
          'full_name',tr.full_name,
          'passport_reference',tr.passport_reference,
          'nationality',tr.nationality,
          'data_classification',tr.data_classification,
          'visa_status',vc.status,
          'documents',coalesce((
            select jsonb_agg(
              jsonb_build_object(
                'type',td.document_type,
                'reference',td.document_reference,
                'status',td.verification_status
              )
            )
            from business.traveler_documents td
            where td.tenant_id=tr.tenant_id
              and td.traveler_id=tr.id
          ),'[]'::jsonb)
        )
      )
      from business.booking_travelers bt
      join business.travelers tr
        on tr.tenant_id=bt.tenant_id
       and tr.id=bt.traveler_id
      left join business.visa_cases vc
        on vc.tenant_id=tr.tenant_id
       and vc.traveler_id=tr.id
      where bt.tenant_id=b.tenant_id
        and bt.booking_id=b.id
    ),'[]'::jsonb),
    'group',coalesce((
      select jsonb_build_object(
        'id',g.id,'code',g.code,'name',g.name
      )
      from business.group_booking_assignments gba
      join business.trip_groups g
        on g.tenant_id=gba.tenant_id
       and g.id=gba.group_id
      where gba.tenant_id=b.tenant_id
        and gba.booking_id=b.id
      limit 1
    ),'{}'::jsonb),
    'supervisor',coalesce((
      select jsonb_build_object(
        'id',s.id,'name',s.display_name,'phone',s.phone
      )
      from business.group_booking_assignments gba
      join business.supervisors s
        on s.tenant_id=gba.tenant_id
       and s.group_id=gba.group_id
      where gba.tenant_id=b.tenant_id
        and gba.booking_id=b.id
      limit 1
    ),'{}'::jsonb),
    'accommodation',coalesce((
      select jsonb_build_object(
        'property_id',pr.id,
        'property_name',pr.name,
        'city',pr.city,
        'room_label',ra.room_label,
        'check_in',ra.check_in,
        'check_out',ra.check_out,
        'source_provenance',pr.source_provenance
      )
      from business.rooming_assignments ra
      join business.properties pr
        on pr.tenant_id=ra.tenant_id
       and pr.id=ra.property_id
      where ra.tenant_id=b.tenant_id
        and ra.booking_id=b.id
      limit 1
    ),'{}'::jsonb),
    'flights',coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'flight_number',f.flight_number,
          'origin',f.origin,
          'destination',f.destination,
          'departure_at',f.departure_at,
          'arrival_at',f.arrival_at,
          'provider',f.provider_name,
          'source_provenance',f.source_provenance
        )
        order by f.departure_at
      )
      from business.flights f
      where f.tenant_id=b.tenant_id
        and f.booking_id=b.id
    ),'[]'::jsonb),
    'transport',coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'mode',gt.mode,
          'operator',gt.operator_name,
          'pickup',gt.pickup,
          'dropoff',gt.dropoff,
          'scheduled_at',gt.scheduled_at,
          'source_provenance',gt.source_provenance
        )
        order by gt.scheduled_at
      )
      from business.ground_transports gt
      where gt.tenant_id=b.tenant_id
        and gt.booking_id=b.id
    ),'[]'::jsonb),
    'support',coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id',sc.id,
          'category',sc.category,
          'summary',sc.summary,
          'status',sc.status
        )
        order by sc.created_at
      )
      from business.support_cases sc
      where sc.tenant_id=b.tenant_id
        and sc.booking_id=b.id
    ),'[]'::jsonb),
    'finance',public.rpc_business_booking_finance_v1(
      b.tenant_id,b.id
    ),
    'freshness','fresh',
    'snapshot_at',now()
  )
  into v_result
  from business.bookings b
  join business.tenants t
    on t.id=b.tenant_id
  join business.departures d
    on d.tenant_id=b.tenant_id
   and d.id=b.departure_id
  join business.packages p
    on p.tenant_id=d.tenant_id
   and p.id=d.package_id
  where b.tenant_id=p_tenant_id
    and b.id=p_booking_id;

  return v_result;
end;
$$;

revoke all on function public.rpc_business_configure_synthetic_trip_operations_v1(uuid,uuid)
  from public,anon;
revoke all on function public.rpc_business_pipeline_summary_v1(uuid)
  from public,anon;
revoke all on function public.rpc_business_umrah_journey_context_v1(uuid,uuid)
  from public,anon;

grant execute on function public.rpc_business_configure_synthetic_trip_operations_v1(uuid,uuid)
  to authenticated;
grant execute on function public.rpc_business_pipeline_summary_v1(uuid)
  to authenticated;
grant execute on function public.rpc_business_umrah_journey_context_v1(uuid,uuid)
  to authenticated;

comment on table business.suppliers is
  'Synthetic-only Phase 7 supplier registry until real-data authority exists.';
comment on function public.rpc_business_umrah_journey_context_v1(uuid,uuid) is
  'Commercial Umrah Journey Context only. Does not create or reinterpret sovereign Hajj status.';

commit;
