-- v2.fn_my_schools()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b8496b0f9e5b9c3491850e310f8de7b5
CREATE OR REPLACE FUNCTION v2.fn_my_schools()
 RETURNS TABLE(id uuid, name_ar text, stage text, students_n integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select s.id, s.name_ar, s.stage,
  (select count(*)::int from v2.enrolments e where e.school_id=s.id and e.status='active')
from v2.schools s where v2.my_school(s.id) order by s.name_ar;
$function$
;
