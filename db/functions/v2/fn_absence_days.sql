-- v2.fn_absence_days(p_student uuid, p_year uuid, p_excused boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 12c6b18a5c253a90db37f42df7f3499c
CREATE OR REPLACE FUNCTION v2.fn_absence_days(p_student uuid, p_year uuid, p_excused boolean)
 RETURNS integer
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
  select count(*)::int from v2.attendance a
   where a.student_id=p_student and a.year_id=p_year and a.state='absent'
     and v2.fn_is_excused(a.student_id, a.on_date) = p_excused;
$function$
;
