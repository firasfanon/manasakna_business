begin;

-- Synthetic identities. Membership user_id intentionally does not require
-- direct auth.users mutation in this isolated authorization proof.
select set_config('request.jwt.claim.sub', '', true);

insert into business.tenants(id, slug, display_name)
values
  ('00000000-0000-4000-8000-0000000000a1', 'tenant-a', 'شركة ألف'),
  ('00000000-0000-4000-8000-0000000000b1', 'tenant-b', 'شركة باء');

insert into business.organizations(id, tenant_id, name)
values
  (
    '00000000-0000-4000-8000-0000000000a2',
    '00000000-0000-4000-8000-0000000000a1',
    'شركة ألف'
  ),
  (
    '00000000-0000-4000-8000-0000000000b2',
    '00000000-0000-4000-8000-0000000000b1',
    'شركة باء'
  );

insert into business.branches(
  id,
  tenant_id,
  organization_id,
  code,
  name
)
values
  (
    '00000000-0000-4000-8000-0000000000a3',
    '00000000-0000-4000-8000-0000000000a1',
    '00000000-0000-4000-8000-0000000000a2',
    'A_MAIN',
    'فرع ألف'
  ),
  (
    '00000000-0000-4000-8000-0000000000b3',
    '00000000-0000-4000-8000-0000000000b1',
    '00000000-0000-4000-8000-0000000000b2',
    'B_MAIN',
    'فرع باء'
  );

insert into business.memberships(tenant_id, user_id, role, status)
values
  (
    '00000000-0000-4000-8000-0000000000a1',
    '00000000-0000-4000-8000-0000000000aa',
    'owner',
    'active'
  ),
  (
    '00000000-0000-4000-8000-0000000000b1',
    '00000000-0000-4000-8000-0000000000bb',
    'owner',
    'active'
  );

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-0000000000aa',
  true
);

do $$
declare
  v_own jsonb;
begin
  select public.rpc_business_list_branches_v1(
    '00000000-0000-4000-8000-0000000000a1'
  )
  into v_own;

  if jsonb_array_length(v_own) <> 1 then
    raise exception 'TENANT_A_OWN_BRANCH_VISIBILITY_FAILED';
  end if;
end;
$$;

do $$
begin
  begin
    perform public.rpc_business_list_branches_v1(
      '00000000-0000-4000-8000-0000000000b1'
    );
    raise exception 'CROSS_TENANT_RPC_READ_WAS_ALLOWED';
  exception
    when insufficient_privilege then
      null;
  end;
end;
$$;

do $$
begin
  begin
    perform count(*) from business.tenants;
    raise exception 'DIRECT_TABLE_ACCESS_WAS_ALLOWED';
  exception
    when insufficient_privilege then
      null;
  end;
end;
$$;

reset role;

do $$
begin
  if business_private.has_scope(
    '00000000-0000-4000-8000-0000000000a1',
    'hajj.eligibility.manage',
    '00000000-0000-4000-8000-0000000000aa'
  ) then
    raise exception 'HAJJ_SOVEREIGN_SCOPE_WAS_ALLOWED';
  end if;
end;
$$;
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-0000000000bb',
  true
);
set local role authenticated;

do $$
declare
  v_own jsonb;
begin
  select public.rpc_business_list_branches_v1(
    '00000000-0000-4000-8000-0000000000b1'
  )
  into v_own;

  if jsonb_array_length(v_own) <> 1 then
    raise exception 'TENANT_B_OWN_BRANCH_VISIBILITY_FAILED';
  end if;
end;
$$;

do $$
begin
  begin
    perform public.rpc_business_list_branches_v1(
      '00000000-0000-4000-8000-0000000000a1'
    );
    raise exception 'CROSS_TENANT_RPC_READ_WAS_ALLOWED_FOR_B';
  exception
    when insufficient_privilege then
      null;
  end;
end;
$$;

rollback;
