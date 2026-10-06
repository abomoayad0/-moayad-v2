-- v2.fn_term_of(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f8098c7adfe9673a41cfbd13c86cc7a7
CREATE OR REPLACE FUNCTION v2.fn_term_of(p_school uuid, p_date date)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce((select w.term_no from v2.calendar_days d
     join v2.calendar_weeks w on w.id = d.week_id
     join v2.calendar_years y on y.id = d.year_id
     join v2.schools s on s.calendar_scope = y.scope_key
    where s.id = p_school and d.on_g = p_date limit 1), 1)::smallint
$function$
;
