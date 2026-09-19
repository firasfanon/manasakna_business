begin;

create extension if not exists pgcrypto with schema extensions;

create schema if not exists business;
create schema if not exists business_private;

revoke all on schema business from public, anon, authenticated;
revoke all on schema business_private from public, anon, authenticated;

create table business.tenants (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique
    check (slug ~ '^[a-z0-9][a-z0-9-]{2,62}$'),
  display_name text not null check (length(trim(display_name)) >= 2),
  authority_domain text not null default 'commercial_umrah'
    check (authority_domain = 'commercial_umrah'),
  status text not null default 'active'
    check (status in ('active', 'suspended', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table business.organizations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  name text not null check (length(trim(name)) >= 2),
  legal_name text,
  registration_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, name)
);

create table business.branches (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  organization_id uuid not null,
  code text not null check (code ~ '^[A-Z0-9_-]{2,24}$'),
  name text not null check (length(trim(name)) >= 2),
  timezone text not null default 'Asia/Hebron',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  unique (tenant_id, code),
  foreign key (tenant_id, organization_id)
    references business.organizations(tenant_id, id)
    on delete cascade
);

create table business.memberships (
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  user_id uuid not null,
  role text not null
    check (role in ('owner', 'admin', 'manager', 'operator', 'viewer')),
  status text not null default 'active'
    check (status in ('invited', 'active', 'suspended', 'revoked')),
  scopes text[] not null default '{}'::text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, user_id)
);

create table business.plans (
  code text primary key,
  name_ar text not null,
  name_en text not null,
  default_entitlements jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table business.subscriptions (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  plan_code text not null references business.plans(code),
  status text not null default 'trial'
    check (status in ('trial', 'active', 'past_due', 'paused', 'canceled')),
  started_at timestamptz not null default now(),
  current_period_end timestamptz,
  created_at timestamptz not null default now()
);

create table business.entitlements (
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  feature_key text not null,
  enabled boolean not null default true,
  limits jsonb not null default '{}'::jsonb,
  source text not null default 'plan'
    check (source in ('plan', 'override', 'system')),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, feature_key)
);

create table business.usage_counters (
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  metric_key text not null,
  period_start date not null,
  period_end date not null,
  quantity bigint not null default 0 check (quantity >= 0),
  updated_at timestamptz not null default now(),
  primary key (tenant_id, metric_key, period_start, period_end),
  check (period_end >= period_start)
);

create table business.tenant_settings (
  tenant_id uuid primary key references business.tenants(id) on delete cascade,
  brand_name_ar text,
  brand_name_en text,
  logo_url text,
  primary_locale text not null default 'ar',
  support_email text,
  support_phone text,
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table business.audit_events (
  id bigint generated always as identity primary key,
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  actor_user_id uuid,
  action text not null,
  target_type text,
  target_id text,
  result text not null check (result in ('allowed', 'denied', 'success', 'failure')),
  metadata jsonb not null default '{}'::jsonb,
  occurred_at timestamptz not null default now()
);

create table business.integration_providers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references business.tenants(id) on delete cascade,
  provider_key text not null,
  provider_type text not null,
  status text not null default 'disabled'
    check (status in ('disabled', 'configured', 'active', 'error')),
  credential_reference text,
  configuration jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, provider_key)
);

create index memberships_user_idx
  on business.memberships(user_id, status);
create index branches_tenant_idx
  on business.branches(tenant_id, is_active);
create index subscriptions_tenant_idx
  on business.subscriptions(tenant_id, status);
create index audit_events_tenant_time_idx
  on business.audit_events(tenant_id, occurred_at desc);
create index integration_providers_tenant_idx
  on business.integration_providers(tenant_id, status);

create or replace function business_private.role_default_scopes(p_role text)
returns text[]
language sql
immutable
set search_path = ''
as $$
  select case p_role
    when 'owner' then array[
      'tenant.read','tenant.manage','branch.read','branch.manage',
      'staff.read','staff.manage','billing.read','billing.manage',
      'settings.read','settings.manage','audit.read',
      'integrations.read','integrations.manage'
    ]::text[]
    when 'admin' then array[
      'tenant.read','tenant.manage','branch.read','branch.manage',
      'staff.read','staff.manage','billing.read',
      'settings.read','settings.manage','audit.read',
      'integrations.read','integrations.manage'
    ]::text[]
    when 'manager' then array[
      'tenant.read','branch.read','branch.manage','staff.read',
      'settings.read','audit.read','integrations.read'
    ]::text[]
    when 'operator' then array[
      'tenant.read','branch.read','staff.read',
      'settings.read','integrations.read'
    ]::text[]
    when 'viewer' then array[
      'tenant.read','branch.read','settings.read'
    ]::text[]
    else '{}'::text[]
  end;
$$;

create or replace function business_private.is_member(
  p_tenant_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user_id is not null
    and exists (
      select 1
      from business.memberships m
      where m.tenant_id = p_tenant_id
        and m.user_id = p_user_id
        and m.status = 'active'
    );
$$;

create or replace function business_private.has_scope(
  p_tenant_id uuid,
  p_scope text,
  p_user_id uuid default auth.uid()
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role text;
  v_scopes text[];
begin
  if p_user_id is null then
    return false;
  end if;

  if p_scope like 'hajj.%' then
    return false;
  end if;

  select m.role, m.scopes
    into v_role, v_scopes
  from business.memberships m
  where m.tenant_id = p_tenant_id
    and m.user_id = p_user_id
    and m.status = 'active';

  if not found then
    return false;
  end if;

  return p_scope = any(business_private.role_default_scopes(v_role))
    or p_scope = any(coalesce(v_scopes, '{}'::text[]));
end;
$$;

create or replace function business_private.assert_scope(
  p_tenant_id uuid,
  p_scope text
)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not business_private.has_scope(p_tenant_id, p_scope, auth.uid()) then
    raise exception 'BUSINESS_SCOPE_DENIED:%', p_scope
      using errcode = '42501';
  end if;
end;
$$;

create or replace function business_private.write_audit(
  p_tenant_id uuid,
  p_action text,
  p_target_type text,
  p_target_id text,
  p_result text,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language sql
volatile
security definer
set search_path = ''
as $$
  insert into business.audit_events(
    tenant_id,
    actor_user_id,
    action,
    target_type,
    target_id,
    result,
    metadata
  )
  values (
    p_tenant_id,
    auth.uid(),
    p_action,
    p_target_type,
    p_target_id,
    p_result,
    coalesce(p_metadata, '{}'::jsonb)
  );
$$;

create or replace function business_private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function business_private.reject_hajj_scopes()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if exists (
    select 1
    from unnest(coalesce(new.scopes, '{}'::text[])) scope_name
    where scope_name like 'hajj.%'
  ) then
    raise exception 'HAJJ_SOVEREIGN_SCOPE_PROHIBITED_IN_BUSINESS'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

create trigger memberships_reject_hajj_scopes
before insert or update of scopes on business.memberships
for each row execute function business_private.reject_hajj_scopes();

create trigger tenants_touch_updated_at
before update on business.tenants
for each row execute function business_private.touch_updated_at();

create trigger organizations_touch_updated_at
before update on business.organizations
for each row execute function business_private.touch_updated_at();

create trigger branches_touch_updated_at
before update on business.branches
for each row execute function business_private.touch_updated_at();

create trigger memberships_touch_updated_at
before update on business.memberships
for each row execute function business_private.touch_updated_at();

create trigger tenant_settings_touch_updated_at
before update on business.tenant_settings
for each row execute function business_private.touch_updated_at();

create trigger integration_providers_touch_updated_at
before update on business.integration_providers
for each row execute function business_private.touch_updated_at();

insert into business.plans(code, name_ar, name_en, default_entitlements)
values
  (
    'starter',
    'البداية',
    'Starter',
    '{"branches":1,"staff":5,"integrations":1}'::jsonb
  ),
  (
    'growth',
    'النمو',
    'Growth',
    '{"branches":5,"staff":25,"integrations":5}'::jsonb
  ),
  (
    'enterprise',
    'المؤسسات',
    'Enterprise',
    '{"branches":null,"staff":null,"integrations":null}'::jsonb
  )
on conflict (code) do nothing;

create or replace function public.rpc_business_create_tenant_v1(
  p_display_name text,
  p_slug text,
  p_organization_name text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_tenant_id uuid;
  v_org_id uuid;
  v_branch_id uuid;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  if p_slug !~ '^[a-z0-9][a-z0-9-]{2,62}$' then
    raise exception 'INVALID_TENANT_SLUG' using errcode = '22023';
  end if;

  insert into business.tenants(slug, display_name)
  values (p_slug, trim(p_display_name))
  returning id into v_tenant_id;

  insert into business.organizations(tenant_id, name)
  values (v_tenant_id, trim(p_organization_name))
  returning id into v_org_id;

  insert into business.branches(
    tenant_id,
    organization_id,
    code,
    name
  )
  values (
    v_tenant_id,
    v_org_id,
    'MAIN',
    'الفرع الرئيسي'
  )
  returning id into v_branch_id;

  insert into business.memberships(
    tenant_id,
    user_id,
    role,
    status
  )
  values (
    v_tenant_id,
    v_user,
    'owner',
    'active'
  );

  insert into business.tenant_settings(
    tenant_id,
    brand_name_ar
  )
  values (
    v_tenant_id,
    trim(p_display_name)
  );

  insert into business.subscriptions(
    tenant_id,
    plan_code,
    status
  )
  values (
    v_tenant_id,
    'starter',
    'trial'
  );

  perform business_private.write_audit(
    v_tenant_id,
    'tenant.create',
    'tenant',
    v_tenant_id::text,
    'success',
    jsonb_build_object('organization_id', v_org_id, 'branch_id', v_branch_id)
  );

  return jsonb_build_object(
    'tenant_id', v_tenant_id,
    'organization_id', v_org_id,
    'branch_id', v_branch_id
  );
end;
$$;

create or replace function public.rpc_business_my_context_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_memberships jsonb;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED' using errcode = '42501';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'tenant_id', m.tenant_id,
        'tenant_name', t.display_name,
        'role', m.role,
        'status', m.status,
        'scopes', m.scopes,
        'plan_code', (
          select s.plan_code
          from business.subscriptions s
          where s.tenant_id = m.tenant_id
            and s.status in ('trial', 'active', 'past_due')
          order by s.started_at desc
          limit 1
        )
      )
      order by t.display_name
    ),
    '[]'::jsonb
  )
  into v_memberships
  from business.memberships m
  join business.tenants t on t.id = m.tenant_id
  where m.user_id = v_user
    and m.status = 'active'
    and t.status = 'active';

  return jsonb_build_object(
    'user_id', v_user,
    'memberships', v_memberships
  );
end;
$$;

create or replace function public.rpc_business_list_branches_v1(
  p_tenant_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform business_private.assert_scope(p_tenant_id, 'branch.read');

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', b.id,
        'organization_id', b.organization_id,
        'code', b.code,
        'name', b.name,
        'timezone', b.timezone,
        'is_active', b.is_active
      )
      order by b.name
    ),
    '[]'::jsonb
  )
  into v_result
  from business.branches b
  where b.tenant_id = p_tenant_id
    and b.is_active;

  return v_result;
end;
$$;

create or replace function public.rpc_business_create_branch_v1(
  p_tenant_id uuid,
  p_organization_id uuid,
  p_code text,
  p_name text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch business.branches%rowtype;
begin
  perform business_private.assert_scope(p_tenant_id, 'branch.manage');

  if not exists (
    select 1
    from business.organizations o
    where o.tenant_id = p_tenant_id
      and o.id = p_organization_id
  ) then
    raise exception 'ORGANIZATION_NOT_IN_TENANT' using errcode = '42501';
  end if;

  insert into business.branches(
    tenant_id,
    organization_id,
    code,
    name
  )
  values (
    p_tenant_id,
    p_organization_id,
    upper(trim(p_code)),
    trim(p_name)
  )
  returning * into v_branch;

  perform business_private.write_audit(
    p_tenant_id,
    'branch.create',
    'branch',
    v_branch.id::text,
    'success'
  );

  return jsonb_build_object(
    'id', v_branch.id,
    'code', v_branch.code,
    'name', v_branch.name
  );
end;
$$;

create or replace function public.rpc_business_upsert_tenant_settings_v1(
  p_tenant_id uuid,
  p_brand_name_ar text,
  p_brand_name_en text,
  p_support_email text,
  p_support_phone text,
  p_settings jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_settings business.tenant_settings%rowtype;
begin
  perform business_private.assert_scope(p_tenant_id, 'settings.manage');

  insert into business.tenant_settings(
    tenant_id,
    brand_name_ar,
    brand_name_en,
    support_email,
    support_phone,
    settings
  )
  values (
    p_tenant_id,
    p_brand_name_ar,
    p_brand_name_en,
    p_support_email,
    p_support_phone,
    coalesce(p_settings, '{}'::jsonb)
  )
  on conflict (tenant_id) do update
  set brand_name_ar = excluded.brand_name_ar,
      brand_name_en = excluded.brand_name_en,
      support_email = excluded.support_email,
      support_phone = excluded.support_phone,
      settings = excluded.settings
  returning * into v_settings;

  perform business_private.write_audit(
    p_tenant_id,
    'tenant.settings.update',
    'tenant_settings',
    p_tenant_id::text,
    'success'
  );

  return jsonb_build_object(
    'tenant_id', v_settings.tenant_id,
    'brand_name_ar', v_settings.brand_name_ar,
    'brand_name_en', v_settings.brand_name_en,
    'support_email', v_settings.support_email,
    'support_phone', v_settings.support_phone,
    'settings', v_settings.settings
  );
end;
$$;

create or replace function public.rpc_business_list_audit_v1(
  p_tenant_id uuid,
  p_limit integer default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform business_private.assert_scope(p_tenant_id, 'audit.read');

  select coalesce(
    jsonb_agg(to_jsonb(a) order by a.occurred_at desc),
    '[]'::jsonb
  )
  into v_result
  from (
    select
      e.id,
      e.actor_user_id,
      e.action,
      e.target_type,
      e.target_id,
      e.result,
      e.metadata,
      e.occurred_at
    from business.audit_events e
    where e.tenant_id = p_tenant_id
    order by e.occurred_at desc
    limit greatest(1, least(coalesce(p_limit, 50), 200))
  ) a;

  return v_result;
end;
$$;

create or replace function public.rpc_business_list_integrations_v1(
  p_tenant_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_result jsonb;
begin
  perform business_private.assert_scope(p_tenant_id, 'integrations.read');

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', i.id,
        'provider_key', i.provider_key,
        'provider_type', i.provider_type,
        'status', i.status,
        'configured', i.credential_reference is not null
      )
      order by i.provider_key
    ),
    '[]'::jsonb
  )
  into v_result
  from business.integration_providers i
  where i.tenant_id = p_tenant_id;

  return v_result;
end;
$$;

create or replace function public.rpc_business_upsert_integration_v1(
  p_tenant_id uuid,
  p_provider_key text,
  p_provider_type text,
  p_status text,
  p_credential_reference text,
  p_configuration jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_provider business.integration_providers%rowtype;
begin
  perform business_private.assert_scope(
    p_tenant_id,
    'integrations.manage'
  );

  if p_credential_reference is not null
     and (
       p_credential_reference like 'sb_secret_%'
       or p_credential_reference like 'sk_%'
       or p_credential_reference like 'eyJ%'
     ) then
    raise exception 'RAW_SECRET_MATERIAL_PROHIBITED'
      using errcode = '22023';
  end if;

  insert into business.integration_providers(
    tenant_id,
    provider_key,
    provider_type,
    status,
    credential_reference,
    configuration
  )
  values (
    p_tenant_id,
    trim(p_provider_key),
    trim(p_provider_type),
    p_status,
    p_credential_reference,
    coalesce(p_configuration, '{}'::jsonb)
  )
  on conflict (tenant_id, provider_key) do update
  set provider_type = excluded.provider_type,
      status = excluded.status,
      credential_reference = excluded.credential_reference,
      configuration = excluded.configuration
  returning * into v_provider;

  perform business_private.write_audit(
    p_tenant_id,
    'integration.upsert',
    'integration_provider',
    v_provider.id::text,
    'success',
    jsonb_build_object('provider_key', v_provider.provider_key)
  );

  return jsonb_build_object(
    'id', v_provider.id,
    'provider_key', v_provider.provider_key,
    'provider_type', v_provider.provider_type,
    'status', v_provider.status
  );
end;
$$;

alter table business.tenants enable row level security;
alter table business.tenants force row level security;
alter table business.organizations enable row level security;
alter table business.organizations force row level security;
alter table business.branches enable row level security;
alter table business.branches force row level security;
alter table business.memberships enable row level security;
alter table business.memberships force row level security;
alter table business.plans enable row level security;
alter table business.plans force row level security;
alter table business.subscriptions enable row level security;
alter table business.subscriptions force row level security;
alter table business.entitlements enable row level security;
alter table business.entitlements force row level security;
alter table business.usage_counters enable row level security;
alter table business.usage_counters force row level security;
alter table business.tenant_settings enable row level security;
alter table business.tenant_settings force row level security;
alter table business.audit_events enable row level security;
alter table business.audit_events force row level security;
alter table business.integration_providers enable row level security;
alter table business.integration_providers force row level security;

revoke all on all tables in schema business
  from public, anon, authenticated;
revoke all on all sequences in schema business
  from public, anon, authenticated;

alter default privileges in schema business
  revoke all on tables from public, anon, authenticated;
alter default privileges in schema business
  revoke all on sequences from public, anon, authenticated;

revoke all on function public.rpc_business_create_tenant_v1(text, text, text)
  from public, anon;
revoke all on function public.rpc_business_my_context_v1()
  from public, anon;
revoke all on function public.rpc_business_list_branches_v1(uuid)
  from public, anon;
revoke all on function public.rpc_business_create_branch_v1(uuid, uuid, text, text)
  from public, anon;
revoke all on function public.rpc_business_upsert_tenant_settings_v1(
  uuid, text, text, text, text, jsonb
) from public, anon;
revoke all on function public.rpc_business_list_audit_v1(uuid, integer)
  from public, anon;
revoke all on function public.rpc_business_list_integrations_v1(uuid)
  from public, anon;
revoke all on function public.rpc_business_upsert_integration_v1(
  uuid, text, text, text, text, jsonb
) from public, anon;

grant execute on function public.rpc_business_create_tenant_v1(text, text, text)
  to authenticated;
grant execute on function public.rpc_business_my_context_v1()
  to authenticated;
grant execute on function public.rpc_business_list_branches_v1(uuid)
  to authenticated;
grant execute on function public.rpc_business_create_branch_v1(uuid, uuid, text, text)
  to authenticated;
grant execute on function public.rpc_business_upsert_tenant_settings_v1(
  uuid, text, text, text, text, jsonb
) to authenticated;
grant execute on function public.rpc_business_list_audit_v1(uuid, integer)
  to authenticated;
grant execute on function public.rpc_business_list_integrations_v1(uuid)
  to authenticated;
grant execute on function public.rpc_business_upsert_integration_v1(
  uuid, text, text, text, text, jsonb
) to authenticated;

comment on schema business is
  'MANASAKNA_BUSINESS commercial tenant data. No sovereign Hajj authority.';
comment on table business.tenants is
  'Commercial company tenant boundary. authority_domain is fixed to commercial_umrah.';
comment on table business.memberships is
  'Tenant-scoped memberships. hajj.* scopes are rejected by trigger.';
comment on table business.integration_providers is
  'Stores provider metadata and opaque credential references, never raw secrets.';

commit;
