-- v2.workdays_after(p_school uuid, p_from date, p_n integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7b846a943570d39b3d550fea02b1fda7
CREATE OR REPLACE FUNCTION v2.workdays_after(p_school uuid, p_from date, p_n integer)
 RETURNS date
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select d.on_g from v2.calendar_days d
   join v2.calendar_years y on y.id=d.year_id
   join v2.schools s on s.calendar_scope=y.scope_key
  where s.id=p_school and d.on_g > p_from and d.day_kind='study'
  order by d.on_g offset greatest(p_n-1,0) limit 1;
$function$
;
