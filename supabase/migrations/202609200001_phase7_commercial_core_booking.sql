begin;

create or replace function business_private.role_default_scopes(p_role text)
returns text[] language sql immutable set search_path = '' as $$
  select case p_role
    when 'owner' then array[
      'tenant.read','tenant.manage','branch.read','branch.manage','staff.read','staff.manage',
      'billing.read','billing.manage','settings.read','settings.manage','audit.read',
      'integrations.read','integrations.manage','crm.read','crm.manage','quote.read','quote.manage',
      'package.read','package.manage','booking.read','booking.manage','traveler.read','traveler.manage',
      'document.read','document.manage','visa.read','visa.manage','finance.read','finance.manage',
      'operations.read','operations.manage','supplier.read','supplier.manage',
      'support.read','support.manage','journey.read'
    ]::text[]
    when 'admin' then array[
      'tenant.read','tenant.manage','branch.read','branch.manage','staff.read','staff.manage',
      'billing.read','settings.read','settings.manage','audit.read','integrations.read','integrations.manage',
      'crm.read','crm.manage','quote.read','quote.manage','package.read','package.manage',
      'booking.read','booking.manage','traveler.read','traveler.manage','document.read','document.manage',
      'visa.read','visa.manage','finance.read','finance.manage','operations.read','operations.manage',
      'supplier.read','supplier.manage','support.read','support.manage','journey.read'
    ]::text[]
    when 'manager' then array[
      'tenant.read','branch.read','branch.manage','staff.read','settings.read','audit.read',
      'integrations.read','crm.read','crm.manage','quote.read','quote.manage','package.read','package.manage',
      'booking.read','booking.manage','traveler.read','traveler.manage','document.read','document.manage',
      'visa.read','visa.manage','finance.read','operations.read','operations.manage',
      'supplier.read','support.read','support.manage','journey.read'
    ]::text[]
    when 'operator' then array[
      'tenant.read','branch.read','staff.read','settings.read','integrations.read','crm.read','crm.manage',
      'quote.read','package.read','booking.read','booking.manage','traveler.read','traveler.manage',
      'document.read','document.manage','visa.read','visa.manage','finance.read',
      'operations.read','operations.manage','support.read','support.manage','journey.read'
    ]::text[]
    when 'viewer' then array[
      'tenant.read','branch.read','settings.read','crm.read','quote.read','package.read','booking.read',
      'traveler.read','document.read','visa.read','finance.read','operations.read',
      'supplier.read','support.read','journey.read'
    ]::text[]
    else '{}'::text[]
  end;
$$;

create table business.customers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  full_name text not null check (length(trim(full_name)) >= 2),
  phone text, email text,
  status text not null default 'active' check (status in ('active','inactive','archived')),
  history jsonb not null default '{}'::jsonb,
  data_classification text not null default 'synthetic' check (data_classification='synthetic'),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (tenant_id,id)
);

create table business.leads (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  customer_id uuid not null,
  source text not null default 'manual',
  status text not null default 'new' check (status in ('new','qualified','quoted','booked','lost')),
  notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,customer_id) references business.customers(tenant_id,id) on delete cascade
);

create table business.quotes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  lead_id uuid not null,
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  total_amount numeric(14,2) not null check (total_amount >= 0),
  price_snapshot jsonb not null, snapshot_hash text not null,
  status text not null default 'draft' check (status in ('draft','sent','accepted','rejected','expired')),
  valid_until date,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,lead_id) references business.leads(tenant_id,id) on delete restrict
);

create table business.packages (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  name text not null,
  duration_days integer not null check (duration_days between 1 and 90),
  description text,
  base_price numeric(14,2) not null check (base_price >= 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  status text not null default 'active' check (status in ('draft','active','inactive')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (tenant_id,id)
);

create table business.departures (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  package_id uuid not null,
  start_date date not null, end_date date not null,
  capacity integer not null check (capacity > 0),
  status text not null default 'open' check (status in ('planned','open','closed','departed','returned','cancelled')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (tenant_id,id), check (end_date >= start_date),
  foreign key (tenant_id,package_id) references business.packages(tenant_id,id) on delete restrict
);

create table business.bookings (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_code text not null, quote_id uuid not null, departure_id uuid not null, customer_id uuid not null,
  status text not null default 'pending' check (status in ('pending','confirmed','cancelled','completed')),
  booked_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (tenant_id,id), unique (tenant_id,booking_code),
  foreign key (tenant_id,quote_id) references business.quotes(tenant_id,id) on delete restrict,
  foreign key (tenant_id,departure_id) references business.departures(tenant_id,id) on delete restrict,
  foreign key (tenant_id,customer_id) references business.customers(tenant_id,id) on delete restrict
);

create table business.travelers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  full_name text not null, passport_reference text not null, nationality text, date_of_birth date,
  data_classification text not null default 'synthetic' check (data_classification='synthetic'),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (tenant_id,id)
);

create table business.booking_travelers (
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_id uuid not null, traveler_id uuid not null,
  traveler_role text not null default 'primary' check (traveler_role in ('primary','companion','child')),
  created_at timestamptz not null default now(),
  primary key (tenant_id,booking_id,traveler_id),
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade,
  foreign key (tenant_id,traveler_id) references business.travelers(tenant_id,id) on delete cascade
);

create table business.traveler_documents (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  traveler_id uuid not null,
  document_type text not null check (document_type in ('passport','photo','vaccination','other')),
  document_reference text not null,
  verification_status text not null default 'pending' check (verification_status in ('pending','verified','rejected','expired')),
  verified_by uuid, verified_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique (tenant_id,id), unique (tenant_id,traveler_id,document_type),
  foreign key (tenant_id,traveler_id) references business.travelers(tenant_id,id) on delete cascade
);

create table business.visa_cases (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  traveler_id uuid not null,
  status text not null default 'not_started'
    check (status in ('not_started','prepared','submitted','under_review','approved','rejected','issued','expired')),
  authority_source text, external_reference text, observed_at timestamptz,
  updated_at timestamptz not null default now(),
  unique (tenant_id,traveler_id),
  foreign key (tenant_id,traveler_id) references business.travelers(tenant_id,id) on delete cascade
);

create table business.finance_entries (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  booking_id uuid not null,
  entry_type text not null check (entry_type in ('charge','payment','refund')),
  amount numeric(14,2) not null check (amount >= 0),
  currency text not null check (currency ~ '^[A-Z]{3}$'),
  reference text,
  data_classification text not null default 'synthetic' check (data_classification='synthetic'),
  occurred_at timestamptz not null default now(), created_at timestamptz not null default now(),
  unique (tenant_id,id),
  foreign key (tenant_id,booking_id) references business.bookings(tenant_id,id) on delete cascade
);

create index leads_tenant_status_idx on business.leads(tenant_id,status,created_at desc);
create index quotes_tenant_status_idx on business.quotes(tenant_id,status,created_at desc);
create index departures_tenant_date_idx on business.departures(tenant_id,start_date,status);
create index bookings_tenant_status_idx on business.bookings(tenant_id,status,booked_at desc);
create index finance_entries_booking_idx on business.finance_entries(tenant_id,booking_id,occurred_at);

create or replace function business_private.reject_quote_price_mutation()
returns trigger language plpgsql set search_path='' as $$
begin
  if old.currency is distinct from new.currency
     or old.total_amount is distinct from new.total_amount
     or old.price_snapshot is distinct from new.price_snapshot
     or old.snapshot_hash is distinct from new.snapshot_hash then
    raise exception 'QUOTE_PRICE_SNAPSHOT_IMMUTABLE' using errcode='42501';
  end if;
  return new;
end;
$$;

create trigger quotes_price_snapshot_immutable before update on business.quotes
for each row execute function business_private.reject_quote_price_mutation();

create trigger customers_touch_updated_at before update on business.customers for each row execute function business_private.touch_updated_at();
create trigger leads_touch_updated_at before update on business.leads for each row execute function business_private.touch_updated_at();
create trigger quotes_touch_updated_at before update on business.quotes for each row execute function business_private.touch_updated_at();
create trigger packages_touch_updated_at before update on business.packages for each row execute function business_private.touch_updated_at();
create trigger departures_touch_updated_at before update on business.departures for each row execute function business_private.touch_updated_at();
create trigger bookings_touch_updated_at before update on business.bookings for each row execute function business_private.touch_updated_at();
create trigger travelers_touch_updated_at before update on business.travelers for each row execute function business_private.touch_updated_at();
create trigger traveler_documents_touch_updated_at before update on business.traveler_documents for each row execute function business_private.touch_updated_at();
create trigger visa_cases_touch_updated_at before update on business.visa_cases for each row execute function business_private.touch_updated_at();

alter table business.customers enable row level security; alter table business.customers force row level security;
alter table business.leads enable row level security; alter table business.leads force row level security;
alter table business.quotes enable row level security; alter table business.quotes force row level security;
alter table business.packages enable row level security; alter table business.packages force row level security;
alter table business.departures enable row level security; alter table business.departures force row level security;
alter table business.bookings enable row level security; alter table business.bookings force row level security;
alter table business.travelers enable row level security; alter table business.travelers force row level security;
alter table business.booking_travelers enable row level security; alter table business.booking_travelers force row level security;
alter table business.traveler_documents enable row level security; alter table business.traveler_documents force row level security;
alter table business.visa_cases enable row level security; alter table business.visa_cases force row level security;
alter table business.finance_entries enable row level security; alter table business.finance_entries force row level security;
revoke all on all tables in schema business from public,anon,authenticated;
revoke all on all sequences in schema business from public,anon,authenticated;

create or replace function public.rpc_business_create_lead_v1(
  p_tenant_id uuid,p_full_name text,p_phone text default null,p_email text default null,
  p_source text default 'manual',p_notes text default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_customer_id uuid; v_lead_id uuid;
begin
  perform business_private.assert_scope(p_tenant_id,'crm.manage');
  insert into business.customers(tenant_id,full_name,phone,email,data_classification)
  values(p_tenant_id,trim(p_full_name),p_phone,p_email,'synthetic') returning id into v_customer_id;
  insert into business.leads(tenant_id,customer_id,source,notes,status)
  values(p_tenant_id,v_customer_id,coalesce(nullif(trim(p_source),''),'manual'),p_notes,'new')
  returning id into v_lead_id;
  perform business_private.write_audit(p_tenant_id,'lead.create','lead',v_lead_id::text,'success',
    jsonb_build_object('data_classification','synthetic'));
  return jsonb_build_object('customer_id',v_customer_id,'lead_id',v_lead_id,'status','new');
end; $$;

create or replace function public.rpc_business_create_quote_v1(
  p_tenant_id uuid,p_lead_id uuid,p_currency text,p_total_amount numeric,
  p_price_snapshot jsonb,p_valid_until date default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_quote_id uuid; v_hash text;
begin
  perform business_private.assert_scope(p_tenant_id,'quote.manage');
  if not exists(select 1 from business.leads where tenant_id=p_tenant_id and id=p_lead_id)
    then raise exception 'LEAD_NOT_IN_TENANT' using errcode='42501'; end if;
  v_hash:=encode(extensions.digest(coalesce(p_price_snapshot,'{}'::jsonb)::text,'sha256'),'hex');
  insert into business.quotes(tenant_id,lead_id,currency,total_amount,price_snapshot,snapshot_hash,status,valid_until)
  values(p_tenant_id,p_lead_id,upper(p_currency),p_total_amount,coalesce(p_price_snapshot,'{}'::jsonb),v_hash,'draft',p_valid_until)
  returning id into v_quote_id;
  update business.leads set status='quoted' where tenant_id=p_tenant_id and id=p_lead_id;
  perform business_private.write_audit(p_tenant_id,'quote.create','quote',v_quote_id::text,'success',
    jsonb_build_object('snapshot_hash',v_hash));
  return jsonb_build_object('quote_id',v_quote_id,'snapshot_hash',v_hash,'status','draft');
end; $$;

create or replace function public.rpc_business_create_package_departure_v1(
  p_tenant_id uuid,p_name text,p_duration_days integer,p_base_price numeric,p_currency text,
  p_start_date date,p_end_date date,p_capacity integer
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_package_id uuid; v_departure_id uuid;
begin
  perform business_private.assert_scope(p_tenant_id,'package.manage');
  insert into business.packages(tenant_id,name,duration_days,base_price,currency,status)
  values(p_tenant_id,trim(p_name),p_duration_days,p_base_price,upper(p_currency),'active')
  returning id into v_package_id;
  insert into business.departures(tenant_id,package_id,start_date,end_date,capacity,status)
  values(p_tenant_id,v_package_id,p_start_date,p_end_date,p_capacity,'open')
  returning id into v_departure_id;
  perform business_private.write_audit(p_tenant_id,'departure.create','departure',v_departure_id::text,'success',
    jsonb_build_object('package_id',v_package_id));
  return jsonb_build_object('package_id',v_package_id,'departure_id',v_departure_id);
end; $$;

create or replace function public.rpc_business_create_booking_v1(
  p_tenant_id uuid,p_quote_id uuid,p_departure_id uuid
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_customer_id uuid; v_lead_id uuid; v_booking_id uuid; v_code text;
begin
  perform business_private.assert_scope(p_tenant_id,'booking.manage');
  select l.customer_id,q.lead_id into v_customer_id,v_lead_id
  from business.quotes q join business.leads l on l.tenant_id=q.tenant_id and l.id=q.lead_id
  where q.tenant_id=p_tenant_id and q.id=p_quote_id;
  if v_customer_id is null then raise exception 'QUOTE_NOT_IN_TENANT' using errcode='42501'; end if;
  if not exists(select 1 from business.departures where tenant_id=p_tenant_id and id=p_departure_id)
    then raise exception 'DEPARTURE_NOT_IN_TENANT' using errcode='42501'; end if;
  v_code:='B-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10));
  insert into business.bookings(tenant_id,booking_code,quote_id,departure_id,customer_id,status)
  values(p_tenant_id,v_code,p_quote_id,p_departure_id,v_customer_id,'confirmed') returning id into v_booking_id;
  update business.quotes set status='accepted' where tenant_id=p_tenant_id and id=p_quote_id;
  update business.leads set status='booked' where tenant_id=p_tenant_id and id=v_lead_id;
  insert into business.finance_entries(tenant_id,booking_id,entry_type,amount,currency,reference,data_classification)
  select p_tenant_id,v_booking_id,'charge',total_amount,currency,'QUOTE:'||id::text,'synthetic'
  from business.quotes where tenant_id=p_tenant_id and id=p_quote_id;
  perform business_private.write_audit(p_tenant_id,'booking.create','booking',v_booking_id::text,'success');
  return jsonb_build_object('booking_id',v_booking_id,'booking_code',v_code,'status','confirmed');
end; $$;

create or replace function public.rpc_business_add_traveler_v1(
  p_tenant_id uuid,p_booking_id uuid,p_full_name text,p_passport_reference text,
  p_nationality text default null,p_date_of_birth date default null,p_traveler_role text default 'primary'
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_traveler_id uuid;
begin
  perform business_private.assert_scope(p_tenant_id,'traveler.manage');
  if not exists(select 1 from business.bookings where tenant_id=p_tenant_id and id=p_booking_id)
    then raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501'; end if;
  insert into business.travelers(tenant_id,full_name,passport_reference,nationality,date_of_birth,data_classification)
  values(p_tenant_id,trim(p_full_name),p_passport_reference,p_nationality,p_date_of_birth,'synthetic')
  returning id into v_traveler_id;
  insert into business.booking_travelers(tenant_id,booking_id,traveler_id,traveler_role)
  values(p_tenant_id,p_booking_id,v_traveler_id,p_traveler_role);
  perform business_private.write_audit(p_tenant_id,'traveler.add','traveler',v_traveler_id::text,'success',
    jsonb_build_object('booking_id',p_booking_id));
  return jsonb_build_object('traveler_id',v_traveler_id);
end; $$;

create or replace function public.rpc_business_upsert_document_v1(
  p_tenant_id uuid,p_traveler_id uuid,p_document_type text,p_document_reference text,
  p_verification_status text default 'pending'
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform business_private.assert_scope(p_tenant_id,'document.manage');
  insert into business.traveler_documents(
    tenant_id,traveler_id,document_type,document_reference,verification_status,verified_by,verified_at)
  values(p_tenant_id,p_traveler_id,p_document_type,p_document_reference,p_verification_status,
    case when p_verification_status='verified' then auth.uid() else null end,
    case when p_verification_status='verified' then now() else null end)
  on conflict(tenant_id,traveler_id,document_type) do update
  set document_reference=excluded.document_reference,verification_status=excluded.verification_status,
      verified_by=excluded.verified_by,verified_at=excluded.verified_at
  returning id into v_id;
  perform business_private.write_audit(p_tenant_id,'document.upsert','traveler_document',v_id::text,'success');
  return jsonb_build_object('document_id',v_id,'status',p_verification_status);
end; $$;

create or replace function public.rpc_business_set_visa_v1(
  p_tenant_id uuid,p_traveler_id uuid,p_status text,p_authority_source text default null,
  p_external_reference text default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform business_private.assert_scope(p_tenant_id,'visa.manage');
  insert into business.visa_cases(tenant_id,traveler_id,status,authority_source,external_reference,observed_at)
  values(p_tenant_id,p_traveler_id,p_status,p_authority_source,p_external_reference,
    case when p_authority_source is not null then now() else null end)
  on conflict(tenant_id,traveler_id) do update
  set status=excluded.status,authority_source=excluded.authority_source,
      external_reference=excluded.external_reference,observed_at=excluded.observed_at
  returning id into v_id;
  perform business_private.write_audit(p_tenant_id,'visa.status','visa_case',v_id::text,'success',
    jsonb_build_object('status',p_status,'authority_source',p_authority_source));
  return jsonb_build_object('visa_case_id',v_id,'status',p_status);
end; $$;

create or replace function public.rpc_business_record_finance_v1(
  p_tenant_id uuid,p_booking_id uuid,p_entry_type text,p_amount numeric,p_currency text,p_reference text default null
) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_id uuid;
begin
  perform business_private.assert_scope(p_tenant_id,'finance.manage');
  insert into business.finance_entries(tenant_id,booking_id,entry_type,amount,currency,reference,data_classification)
  values(p_tenant_id,p_booking_id,p_entry_type,p_amount,upper(p_currency),p_reference,'synthetic') returning id into v_id;
  perform business_private.write_audit(p_tenant_id,'finance.record','finance_entry',v_id::text,'success',
    jsonb_build_object('entry_type',p_entry_type,'amount',p_amount));
  return jsonb_build_object('finance_entry_id',v_id);
end; $$;

create or replace function public.rpc_business_booking_finance_v1(p_tenant_id uuid,p_booking_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_charge numeric; v_payment numeric; v_refund numeric; v_currency text;
begin
  perform business_private.assert_scope(p_tenant_id,'finance.read');
  select coalesce(sum(amount) filter(where entry_type='charge'),0),
         coalesce(sum(amount) filter(where entry_type='payment'),0),
         coalesce(sum(amount) filter(where entry_type='refund'),0),max(currency)
  into v_charge,v_payment,v_refund,v_currency
  from business.finance_entries where tenant_id=p_tenant_id and booking_id=p_booking_id;
  return jsonb_build_object('charge',v_charge,'payment',v_payment,'refund',v_refund,
    'balance',v_charge-v_payment+v_refund,'currency',v_currency);
end; $$;

create or replace function public.rpc_business_list_bookings_v1(p_tenant_id uuid)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_result jsonb;
begin
  perform business_private.assert_scope(p_tenant_id,'booking.read');
  select coalesce(jsonb_agg(row_data),'[]'::jsonb) into v_result
  from (
    select jsonb_build_object(
      'id',b.id,'booking_code',b.booking_code,'status',b.status,'booked_at',b.booked_at,
      'customer_name',c.full_name,'package_name',p.name,'departure_start',d.start_date
    ) row_data
    from business.bookings b
    join business.customers c on c.tenant_id=b.tenant_id and c.id=b.customer_id
    join business.departures d on d.tenant_id=b.tenant_id and d.id=b.departure_id
    join business.packages p on p.tenant_id=d.tenant_id and p.id=d.package_id
    where b.tenant_id=p_tenant_id order by b.booked_at desc
  ) q;
  return v_result;
end; $$;

revoke all on function public.rpc_business_create_lead_v1(uuid,text,text,text,text,text) from public,anon;
revoke all on function public.rpc_business_create_quote_v1(uuid,uuid,text,numeric,jsonb,date) from public,anon;
revoke all on function public.rpc_business_create_package_departure_v1(uuid,text,integer,numeric,text,date,date,integer) from public,anon;
revoke all on function public.rpc_business_create_booking_v1(uuid,uuid,uuid) from public,anon;
revoke all on function public.rpc_business_add_traveler_v1(uuid,uuid,text,text,text,date,text) from public,anon;
revoke all on function public.rpc_business_upsert_document_v1(uuid,uuid,text,text,text) from public,anon;
revoke all on function public.rpc_business_set_visa_v1(uuid,uuid,text,text,text) from public,anon;
revoke all on function public.rpc_business_record_finance_v1(uuid,uuid,text,numeric,text,text) from public,anon;
revoke all on function public.rpc_business_booking_finance_v1(uuid,uuid) from public,anon;
revoke all on function public.rpc_business_list_bookings_v1(uuid) from public,anon;

grant execute on function public.rpc_business_create_lead_v1(uuid,text,text,text,text,text) to authenticated;
grant execute on function public.rpc_business_create_quote_v1(uuid,uuid,text,numeric,jsonb,date) to authenticated;
grant execute on function public.rpc_business_create_package_departure_v1(uuid,text,integer,numeric,text,date,date,integer) to authenticated;
grant execute on function public.rpc_business_create_booking_v1(uuid,uuid,uuid) to authenticated;
grant execute on function public.rpc_business_add_traveler_v1(uuid,uuid,text,text,text,date,text) to authenticated;
grant execute on function public.rpc_business_upsert_document_v1(uuid,uuid,text,text,text) to authenticated;
grant execute on function public.rpc_business_set_visa_v1(uuid,uuid,text,text,text) to authenticated;
grant execute on function public.rpc_business_record_finance_v1(uuid,uuid,text,numeric,text,text) to authenticated;
grant execute on function public.rpc_business_booking_finance_v1(uuid,uuid) to authenticated;
grant execute on function public.rpc_business_list_bookings_v1(uuid) to authenticated;

comment on table business.customers is 'Phase 7 commercial Umrah customer records; V1 is synthetic-only.';
comment on table business.quotes is 'Commercial quote with immutable price snapshot.';
comment on table business.finance_entries is 'Operational finance only; not a general ledger or payment processor.';

commit;
