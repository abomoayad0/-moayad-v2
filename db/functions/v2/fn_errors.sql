-- v2.fn_errors(p_days integer, p_kind text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 25d1db9a0746db99c3de8d19c8ee3136
CREATE OR REPLACE FUNCTION v2.fn_errors(p_days integer DEFAULT 7, p_kind text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, at timestamp with time zone, person_ar text, role_ar text, school_ar text, screen text, action text, fn_name text, kind text, message text, sqlstate text, params jsonb, seen boolean, fixed boolean, times integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select (array_agg(e.id order by e.at desc))[1], max(e.at),
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
  order by max(e.at) desc
$function$
;
