-- v2.fn_school_days(p_school uuid, p_from date, p_to date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 981f723a9eeca61b506fdb6f682ae2cd
CREATE OR REPLACE FUNCTION v2.fn_school_days(p_school uuid, p_from date, p_to date)
 RETURNS integer
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
  select count(*)::int from v2.calendar_days d
  join v2.calendar_years y on y.id = d.year_id
  join v2.schools s on s.calendar_scope = y.scope_key
  where s.id = p_school and d.on_g between p_from and p_to
    and d.day_kind in ('study','exam');
$function$
;
