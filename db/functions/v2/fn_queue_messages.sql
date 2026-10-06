-- v2.fn_queue_messages(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4a8ae707b08670bc8282553127e2a88e
CREATE OR REPLACE FUNCTION v2.fn_queue_messages(p_school uuid DEFAULT NULL::uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("جُهّز" integer, "بلا_جوال" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n int := 0; m int := 0;
begin
  insert into v2.outbox (school_id, delivery_id, channel, to_phone, to_name, body_ar)
  select ev.school_id, d.id, 'whatsapp', g.phone, g.full_name,
    ev.title_ar||E'\n'||ev.body_ar||
    case when ev.needs_action then E'\n\nالمطلوب: '||ev.action_ar else '' end||
    E'\n\n— '||sc.name_ar
  from v2.event_deliveries d
  join v2.events ev on ev.id=d.event_id
  join v2.guardians g on g.id=d.to_guardian
  join v2.schools sc on sc.id=ev.school_id
  where d.channel='whatsapp' and d.status='queued'
    and (p_school is null or ev.school_id=p_school)
    and ev.on_date = p_date
    and g.phone is not null
    and not exists (select 1 from v2.outbox o where o.delivery_id=d.id);
  get diagnostics n = row_count;

  select count(*) into m from v2.event_deliveries d
   join v2.events ev on ev.id=d.event_id
   join v2.guardians g on g.id=d.to_guardian
   where d.channel='whatsapp' and d.status='queued' and ev.on_date=p_date
     and (p_school is null or ev.school_id=p_school) and g.phone is null;
  return query select n, m;
end $function$
;
