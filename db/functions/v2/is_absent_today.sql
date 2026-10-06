-- v2.is_absent_today(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8c74e3e69c3f20601333dcf6a4ab9484
CREATE OR REPLACE FUNCTION v2.is_absent_today(p_student uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select exists (select 1 from v2.attendance a
    where a.student_id = p_student
      and a.on_date = current_date
      and a.state = 'absent');
$function$
;
