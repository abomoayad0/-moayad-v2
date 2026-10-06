-- v2.fn_attendance_balance(p_student uuid, p_year uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5f3cc1f8af115fb8aa9ff5577cb1e0b4
CREATE OR REPLACE FUNCTION v2.fn_attendance_balance(p_student uuid, p_year uuid)
 RETURNS numeric
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
  select case when not exists (
      select 1 from v2.attendance_ledger where student_id=p_student and year_id=p_year)
    then (select value_num from v2.conduct_rules where key='attendance.total')
    else least(100, greatest(0, (select coalesce(sum(points),0)
      from v2.attendance_ledger where student_id=p_student and year_id=p_year))) end;
$function$
;
