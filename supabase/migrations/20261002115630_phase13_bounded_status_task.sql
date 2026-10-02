-- Materialized from live non-production Supabase migration history.
-- Project: nghxemiygpjywkodrdwx
-- Migration: phase13_bounded_status_task
-- Version: 20261002115630

create or replace function public.rpc_business_phase13_update_status_v1(p_tenant_id uuid,p_resource text,p_id uuid,p_status text,p_reason text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_old text; v jsonb;
begin
 if p_resource='lead' then
  perform business_private.assert_scope(p_tenant_id,'crm.manage');
  select status into v_old from business.leads where tenant_id=p_tenant_id and id=p_id for update;
  if v_old is null then raise exception 'LEAD_NOT_IN_TENANT' using errcode='42501'; end if;
  if not ((v_old='new' and p_status in('qualified','lost')) or (v_old='qualified' and p_status in('quoted','lost')) or (v_old='quoted' and p_status in('booked','lost')) or v_old=p_status) then raise exception 'INVALID_LEAD_TRANSITION:%->%',v_old,p_status using errcode='22023'; end if;
  if p_status='lost' and coalesce(trim(p_reason),'')='' then raise exception 'LOST_REASON_REQUIRED' using errcode='23514'; end if;
  update business.leads set status=p_status,lost_reason=case when p_status='lost' then p_reason else lost_reason end,updated_at=now(),updated_by=auth.uid(),version=version+1 where tenant_id=p_tenant_id and id=p_id returning to_jsonb(business.leads.*) into v;
 elsif p_resource='quote' then
  perform business_private.assert_scope(p_tenant_id,'quote.manage');
  select status into v_old from business.quotes where tenant_id=p_tenant_id and id=p_id for update;
  if v_old is null then raise exception 'QUOTE_NOT_IN_TENANT' using errcode='42501'; end if;
  if not ((v_old='draft' and p_status in('sent','rejected')) or (v_old='sent' and p_status in('accepted','rejected','expired')) or v_old=p_status) then raise exception 'INVALID_QUOTE_TRANSITION:%->%',v_old,p_status using errcode='22023'; end if;
  update business.quotes set status=p_status,accepted_at=case when p_status='accepted' then now() else accepted_at end,updated_at=now(),updated_by=auth.uid() where tenant_id=p_tenant_id and id=p_id returning to_jsonb(business.quotes.*) into v;
 elsif p_resource='task' then
  perform business_private.assert_scope(p_tenant_id,'operations.manage');
  select status into v_old from business.operational_tasks where tenant_id=p_tenant_id and id=p_id for update;
  if v_old is null then raise exception 'TASK_NOT_IN_TENANT' using errcode='42501'; end if;
  if not ((v_old='open' and p_status in('in_progress','done','cancelled')) or (v_old='in_progress' and p_status in('done','cancelled')) or v_old=p_status) then raise exception 'INVALID_TASK_TRANSITION:%->%',v_old,p_status using errcode='22023'; end if;
  update business.operational_tasks set status=p_status,completed_at=case when p_status='done' then now() else completed_at end,updated_at=now() where tenant_id=p_tenant_id and id=p_id returning to_jsonb(business.operational_tasks.*) into v;
 elsif p_resource='support' then
  perform business_private.assert_scope(p_tenant_id,'support.manage');
  select status into v_old from business.support_cases where tenant_id=p_tenant_id and id=p_id for update;
  if v_old is null then raise exception 'SUPPORT_NOT_IN_TENANT' using errcode='42501'; end if;
  if not ((v_old='open' and p_status in('pending','resolved')) or (v_old='pending' and p_status in('open','resolved')) or (v_old='resolved' and p_status='closed') or v_old=p_status) then raise exception 'INVALID_SUPPORT_TRANSITION:%->%',v_old,p_status using errcode='22023'; end if;
  update business.support_cases set status=p_status,resolution=case when p_status in('resolved','closed') then coalesce(p_reason,resolution) else resolution end,resolved_at=case when p_status='resolved' then now() else resolved_at end,updated_at=now() where tenant_id=p_tenant_id and id=p_id returning to_jsonb(business.support_cases.*) into v;
 else raise exception 'UNSUPPORTED_STATUS_RESOURCE:%',p_resource using errcode='22023'; end if;
 perform business_private.write_audit(p_tenant_id,'phase13.status.update',p_resource,p_id::text,'success',jsonb_build_object('from',v_old,'to',p_status,'reason',p_reason));
 return v;
end $$;
revoke all on function public.rpc_business_phase13_update_status_v1(uuid,text,uuid,text,text) from public,anon;
grant execute on function public.rpc_business_phase13_update_status_v1(uuid,text,uuid,text,text) to authenticated;

create or replace function public.rpc_business_phase13_save_task_v1(p_tenant_id uuid,p_task_id uuid,p_booking_id uuid,p_payload jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v business.operational_tasks%rowtype;
begin
 perform business_private.assert_scope(p_tenant_id,'operations.manage');
 if not exists(select 1 from business.bookings where tenant_id=p_tenant_id and id=p_booking_id) then raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501'; end if;
 if coalesce(trim(p_payload->>'title'),'')='' then raise exception 'TASK_TITLE_REQUIRED' using errcode='23514'; end if;
 if p_task_id is null then insert into business.operational_tasks(tenant_id,booking_id,title,status,due_at,task_type,priority,correlation_id) values(p_tenant_id,p_booking_id,trim(p_payload->>'title'),'open',nullif(p_payload->>'due_at','')::timestamptz,coalesce(nullif(p_payload->>'task_type',''),'general'),coalesce(nullif(p_payload->>'priority',''),'normal'),gen_random_uuid()) returning * into v;
 else update business.operational_tasks set title=trim(p_payload->>'title'),due_at=nullif(p_payload->>'due_at','')::timestamptz,task_type=coalesce(nullif(p_payload->>'task_type',''),task_type),priority=coalesce(nullif(p_payload->>'priority',''),priority),updated_at=now() where tenant_id=p_tenant_id and id=p_task_id returning * into v; if v.id is null then raise exception 'TASK_NOT_IN_TENANT' using errcode='42501'; end if; end if;
 perform business_private.write_audit(p_tenant_id,'phase13.task.save','task',v.id::text,'success','{}'::jsonb); return to_jsonb(v);
end $$;
revoke all on function public.rpc_business_phase13_save_task_v1(uuid,uuid,uuid,jsonb) from public,anon;
grant execute on function public.rpc_business_phase13_save_task_v1(uuid,uuid,uuid,jsonb) to authenticated;
