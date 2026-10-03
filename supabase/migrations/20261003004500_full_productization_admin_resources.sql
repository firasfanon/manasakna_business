-- Full-productization administrative resources.
-- Supabase CLI is unavailable on the execution host; this migration was
-- authored as a bounded source file and is applied through governed MCP.
create or replace function public.rpc_business_product_admin_list_v1(
  p_tenant_id uuid,
  p_resource text
) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare v jsonb;
begin
  if p_resource='organizations' then
    perform business_private.assert_scope(p_tenant_id,'tenant.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (
      select id,tenant_id,name,legal_name,registration_number
      from business.organizations
      where tenant_id=p_tenant_id order by name
    ) x;
  elsif p_resource='branches' then
    perform business_private.assert_scope(p_tenant_id,'branch.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (
      select id,tenant_id,organization_id,code,name,timezone,is_active
      from business.branches
      where tenant_id=p_tenant_id order by name
    ) x;
  elsif p_resource='staff' then
    perform business_private.assert_scope(p_tenant_id,'staff.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (
      select m.user_id as id,m.tenant_id,m.user_id,
             coalesce(u.email,'') as email,m.role,m.status,m.scopes,
             m.created_at,m.updated_at
      from business.memberships m
      left join auth.users u on u.id=m.user_id
      where m.tenant_id=p_tenant_id
      order by coalesce(u.email,m.user_id::text)
    ) x;
  elsif p_resource='settings' then
    perform business_private.assert_scope(p_tenant_id,'settings.read');
    select coalesce(jsonb_agg(to_jsonb(x)),'[]'::jsonb) into v
    from (
      select tenant_id as id,tenant_id,brand_name_ar,brand_name_en,logo_url,
             primary_locale,support_email,support_phone,settings,updated_at
      from business.tenant_settings
      where tenant_id=p_tenant_id
    ) x;
  else
    raise exception 'UNSUPPORTED_ADMIN_RESOURCE:%',p_resource using errcode='22023';
  end if;
  return v;
end
$$;

revoke all on function public.rpc_business_product_admin_list_v1(uuid,text)
from public,anon;
grant execute on function public.rpc_business_product_admin_list_v1(uuid,text)
to authenticated;
create or replace function public.rpc_business_product_admin_save_v1(
  p_tenant_id uuid,
  p_resource text,
  p_id uuid,
  p_payload jsonb
) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v jsonb;
begin
  if p_resource='settings' then
    perform business_private.assert_scope(p_tenant_id,'settings.manage');
    insert into business.tenant_settings(
      tenant_id,brand_name_ar,brand_name_en,primary_locale,
      support_email,support_phone,settings
    ) values(
      p_tenant_id,nullif(trim(p_payload->>'brand_name_ar'),''),
      nullif(trim(p_payload->>'brand_name_en'),''),
      coalesce(nullif(trim(p_payload->>'primary_locale'),''),'ar'),
      nullif(trim(p_payload->>'support_email'),''),
      nullif(trim(p_payload->>'support_phone'),''),
      coalesce(p_payload->'settings','{}'::jsonb)
    )
    on conflict(tenant_id) do update set
      brand_name_ar=excluded.brand_name_ar,
      brand_name_en=excluded.brand_name_en,
      primary_locale=excluded.primary_locale,
      support_email=excluded.support_email,
      support_phone=excluded.support_phone,
      settings=excluded.settings,
      updated_at=now()
    returning to_jsonb(tenant_settings.*) into v;
    perform business_private.write_audit(
      p_tenant_id,'tenant.settings.update','tenant_settings',
      p_tenant_id::text,'success',
      jsonb_build_object('source','full_productization_admin')
    );
    return v;

  elsif p_resource='branch' then
    perform business_private.assert_scope(p_tenant_id,'branch.manage');
    if p_id is null then
      insert into business.branches(
        tenant_id,organization_id,code,name,timezone,is_active
      ) values(
        p_tenant_id,(p_payload->>'organization_id')::uuid,
        upper(trim(p_payload->>'code')),trim(p_payload->>'name'),
        coalesce(nullif(trim(p_payload->>'timezone'),''),'Asia/Hebron'),
        coalesce(nullif(p_payload->>'is_active','')::boolean,true)
      ) returning to_jsonb(branches.*) into v;
    else
      update business.branches set
        organization_id=coalesce(nullif(p_payload->>'organization_id','')::uuid,organization_id),
        code=coalesce(upper(nullif(trim(p_payload->>'code'),'')),code),
        name=coalesce(nullif(trim(p_payload->>'name'),''),name),
        timezone=coalesce(nullif(trim(p_payload->>'timezone'),''),timezone),
        is_active=coalesce(nullif(p_payload->>'is_active','')::boolean,is_active)
      where tenant_id=p_tenant_id and id=p_id
      returning to_jsonb(branches.*) into v;
    end if;
    if v is null then raise exception 'BRANCH_NOT_IN_TENANT' using errcode='42501'; end if;
    perform business_private.write_audit(
      p_tenant_id,'branch.save','branch',v->>'id','success',
      jsonb_build_object('source','full_productization_admin')
    );
    return v;

  elsif p_resource='staff' then
    perform business_private.assert_scope(p_tenant_id,'staff.manage');
    if p_id is null then
      raise exception 'STAFF_INVITATION_REQUIRES_AUTH_ADMIN_CHANNEL' using errcode='0A000';
    end if;
    update business.memberships set
      role=coalesce(nullif(trim(p_payload->>'role'),''),role),
      status=coalesce(nullif(trim(p_payload->>'status'),''),status),
      updated_at=now()
    where tenant_id=p_tenant_id and user_id=p_id
    returning jsonb_build_object(
      'id',user_id,'tenant_id',tenant_id,'user_id',user_id,
      'role',role,'status',status,'scopes',scopes
    ) into v;
    if v is null then raise exception 'STAFF_NOT_IN_TENANT' using errcode='42501'; end if;
    perform business_private.write_audit(
      p_tenant_id,'staff.membership.update','membership',p_id::text,'success',
      jsonb_build_object('role',v->>'role','status',v->>'status')
    );
    return v;
  end if;
  raise exception 'UNSUPPORTED_ADMIN_RESOURCE:%',p_resource using errcode='22023';
end
$$;
revoke all on function public.rpc_business_product_admin_save_v1(
  uuid,text,uuid,jsonb
) from public,anon;
grant execute on function public.rpc_business_product_admin_save_v1(
  uuid,text,uuid,jsonb
) to authenticated;
