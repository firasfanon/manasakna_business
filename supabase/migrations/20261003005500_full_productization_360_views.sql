-- Server-derived 360 views for customer, booking and departure.
create or replace function public.rpc_business_product_360_v1(
  p_tenant_id uuid,
  p_entity text,
  p_id uuid
) returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare
  rec jsonb;
  sections jsonb:='{}'::jsonb;
  readiness jsonb:=null;
begin
  if p_entity='customer' then
    perform business_private.assert_scope(p_tenant_id,'crm.read');
    select to_jsonb(c) into rec
    from business.customers c
    where c.tenant_id=p_tenant_id and c.id=p_id;
    if rec is null then
      raise exception 'CUSTOMER_NOT_IN_TENANT' using errcode='42501';
    end if;
    sections:=jsonb_build_object(
      'الفرص',
      coalesce((
        select jsonb_agg(to_jsonb(l) order by l.updated_at desc)
        from business.leads l
        where l.tenant_id=p_tenant_id and l.customer_id=p_id
      ),'[]'::jsonb),
      'العروض',
      coalesce((
        select jsonb_agg(to_jsonb(q) order by q.updated_at desc)
        from business.quotes q
        join business.leads l on l.tenant_id=q.tenant_id and l.id=q.lead_id
        where q.tenant_id=p_tenant_id and l.customer_id=p_id
      ),'[]'::jsonb),
      'الحجوزات',
      coalesce((
        select jsonb_agg(to_jsonb(b) order by b.updated_at desc)
        from business.bookings b
        join business.quotes q on q.tenant_id=b.tenant_id and q.id=b.quote_id
        join business.leads l on l.tenant_id=q.tenant_id and l.id=q.lead_id
        where b.tenant_id=p_tenant_id and l.customer_id=p_id
      ),'[]'::jsonb)
    );

  elsif p_entity='booking' then
    perform business_private.assert_scope(p_tenant_id,'booking.read');
    select to_jsonb(b) into rec
    from business.bookings b
    where b.tenant_id=p_tenant_id and b.id=p_id;
    if rec is null then
      raise exception 'BOOKING_NOT_IN_TENANT' using errcode='42501';
    end if;
    sections:=jsonb_build_object(
      'المسافرون',
      coalesce((
        select jsonb_agg(to_jsonb(t) order by t.full_name)
        from business.booking_travelers bt
        join business.travelers t
          on t.tenant_id=bt.tenant_id and t.id=bt.traveler_id
        where bt.tenant_id=p_tenant_id and bt.booking_id=p_id
      ),'[]'::jsonb),
      'الوثائق',
      coalesce((
        select jsonb_agg(to_jsonb(d) order by d.updated_at desc)
        from business.booking_travelers bt
        join business.traveler_documents d
          on d.tenant_id=bt.tenant_id and d.traveler_id=bt.traveler_id
        where bt.tenant_id=p_tenant_id and bt.booking_id=p_id
      ),'[]'::jsonb),
      'التأشيرات',
      coalesce((
        select jsonb_agg(to_jsonb(v) order by v.updated_at desc)
        from business.booking_travelers bt
        join business.visa_cases v
          on v.tenant_id=bt.tenant_id and v.traveler_id=bt.traveler_id
        where bt.tenant_id=p_tenant_id and bt.booking_id=p_id
      ),'[]'::jsonb),
      'الإقامة والغرف',
      coalesce((
        select jsonb_agg(to_jsonb(r) order by r.created_at desc)
        from business.rooming_assignments r
        where r.tenant_id=p_tenant_id and r.booking_id=p_id
      ),'[]'::jsonb),
      'الطيران',
      coalesce((
        select jsonb_agg(to_jsonb(f) order by f.departure_at)
        from business.flights f
        where f.tenant_id=p_tenant_id and f.booking_id=p_id
      ),'[]'::jsonb),
      'النقل',
      coalesce((
        select jsonb_agg(to_jsonb(g) order by g.scheduled_at)
        from business.ground_transports g
        where g.tenant_id=p_tenant_id and g.booking_id=p_id
      ),'[]'::jsonb),
      'المالية',
      coalesce((
        select jsonb_agg(to_jsonb(f) order by f.occurred_at desc)
        from business.finance_entries f
        where f.tenant_id=p_tenant_id and f.booking_id=p_id
      ),'[]'::jsonb),
      'المهام',
      coalesce((
        select jsonb_agg(to_jsonb(t) order by t.updated_at desc)
        from business.operational_tasks t
        where t.tenant_id=p_tenant_id and t.booking_id=p_id
      ),'[]'::jsonb),
      'الدعم',
      coalesce((
        select jsonb_agg(to_jsonb(s) order by s.updated_at desc)
        from business.support_cases s
        where s.tenant_id=p_tenant_id and s.booking_id=p_id
      ),'[]'::jsonb)
    );
    readiness:=public.rpc_business_booking_readiness_v1(p_tenant_id,p_id);

  elsif p_entity='departure' then
    perform business_private.assert_scope(p_tenant_id,'package.read');
    select to_jsonb(d) into rec
    from business.departures d
    where d.tenant_id=p_tenant_id and d.id=p_id;
    if rec is null then
      raise exception 'DEPARTURE_NOT_IN_TENANT' using errcode='42501';
    end if;
    sections:=jsonb_build_object(
      'الحجوزات',
      coalesce((
        select jsonb_agg(to_jsonb(b) order by b.updated_at desc)
        from business.bookings b
        where b.tenant_id=p_tenant_id and b.departure_id=p_id
      ),'[]'::jsonb),
      'المجموعات',
      coalesce((
        select jsonb_agg(to_jsonb(g) order by g.created_at desc)
        from business.trip_groups g
        where g.tenant_id=p_tenant_id and g.departure_id=p_id
      ),'[]'::jsonb),
      'المشرفون',
      coalesce((
        select jsonb_agg(to_jsonb(s) order by s.created_at desc)
        from business.trip_groups g
        join business.supervisors s
          on s.tenant_id=g.tenant_id and s.group_id=g.id
        where g.tenant_id=p_tenant_id and g.departure_id=p_id
      ),'[]'::jsonb)
    );
  else
    raise exception 'UNSUPPORTED_360_ENTITY:%',p_entity using errcode='22023';
  end if;

  return jsonb_build_object(
    'entity',p_entity,
    'record',rec,
    'sections',sections,
    'readiness',readiness
  );
end
$$;

revoke all on function public.rpc_business_product_360_v1(uuid,text,uuid)
from public,anon;
grant execute on function public.rpc_business_product_360_v1(uuid,text,uuid)
to authenticated;
