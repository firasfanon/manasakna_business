-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_tenant_negative_test_harness
-- Version: 20261002115425

create or replace function business_private.phase13_tenant_negative_test_once()
returns jsonb language plpgsql security definer set search_path='' as $$
declare
 a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); u uuid:=gen_random_uuid();
 same_ok boolean:=false; cross_denied boolean:=false; hajj_denied boolean:=false;
begin
 insert into business.tenants(id,slug,display_name) values
 (a,'p13-a-'||replace(a::text,'-',''),'P13 synthetic tenant A'),
 (b,'p13-b-'||replace(b::text,'-',''),'P13 synthetic tenant B');
 insert into business.memberships(tenant_id,user_id,role,status) values(a,u,'owner','active');
 perform set_config('request.jwt.claim.sub',u::text,true);
 begin perform public.rpc_business_phase13_dashboard_v1(a); same_ok:=true; exception when others then same_ok:=false; end;
 begin perform public.rpc_business_phase13_dashboard_v1(b); exception when insufficient_privilege then cross_denied:=true; when others then cross_denied:=position('BUSINESS_SCOPE_DENIED' in sqlerrm)>0; end;
 hajj_denied:=not business_private.has_scope(a,'hajj.manage',u);
 delete from business.tenants where id in(a,b);
 return jsonb_build_object(
  'same_tenant_rpc_allowed',same_ok,
  'cross_tenant_rpc_denied',cross_denied,
  'hajj_scope_denied',hajj_denied,
  'anon_direct_customers_select',has_table_privilege('anon','business.customers','select'),
  'authenticated_direct_customers_select',has_table_privilege('authenticated','business.customers','select'),
  'anon_advance_rpc_execute',has_function_privilege('anon','public.rpc_business_advance_booking_stage_v1(uuid,uuid,text,text,text)','execute')
 );
exception when others then
 delete from business.tenants where id in(a,b);
 raise;
end $$;
revoke all on function business_private.phase13_tenant_negative_test_once() from public,anon,authenticated;
