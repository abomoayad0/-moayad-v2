-- v2.fn_day_kind(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0c60767ca681a9633d6bdb204343a08c
CREATE OR REPLACE FUNCTION v2.fn_day_kind(p_school uuid, p_date date)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
  select d.day_kind from v2.calendar_days d
  join v2.calendar_years y on y.id = d.year_id
  join v2.schools s on s.calendar_scope = y.scope_key
  where s.id = p_school and d.on_g = p_date
  limit 1;
$function$
;
