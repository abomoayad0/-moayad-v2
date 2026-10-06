-- public.v2_errors(p_days integer, p_kind text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 be202e8fd00ec4222e0d56c422eaeb05
CREATE OR REPLACE FUNCTION public.v2_errors(p_days integer DEFAULT 7, p_kind text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, at timestamp with time zone, at_h text, at_ar text, person_ar text, role_ar text, school_ar text, screen text, action text, fn_name text, kind text, message text, sqlstate text, params jsonb, seen boolean, fixed boolean, times integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if v2.my_grant() not in ('owner','admin') then
    raise exception 'لوحة الأخطاء للمالك وإدارة المدرسة'; end if;
  return query
  select (array_agg(e.id order by e.at desc))[1], max(e.at),
   v2.fn_to_hijri((max(e.at) at time zone 'Asia/Riyadh')::date),
   v2.fn_to_hijri((max(e.at) at time zone 'Asia/Riyadh')::date)||' هـ · '||
     to_char(max(e.at) at time zone 'Asia/Riyadh','HH24:MI'),
   (array_agg(e.person_ar order by e.at desc))[1],
   (array_agg(e.role_ar order by e.at desc))[1],
   (array_agg(e.school_ar order by e.at desc))[1],
   e.screen, e.action, e.fn_name, e.kind, e.message, e.sqlstate,
   (array_agg(e.params order by e.at desc))[1],
   bool_and(e.seen), bool_and(e.fixed), count(*)::int
  from v2.error_log e
  where e.at > now() - make_interval(days => p_days)
    and (p_kind is null or e.kind = p_kind)
  group by e.screen, e.action, e.fn_name, e.kind, e.message, e.sqlstate
  order by max(e.at) desc;
end $function$
;
