-- v2.fn_guardian_me()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 17a1c99a7901293f7d9f9606656c16eb
CREATE OR REPLACE FUNCTION v2.fn_guardian_me()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select case when count(*)=0 then null else jsonb_build_object(
 'name', max(g.full_name), 'phone', max(g.phone),
 'children', jsonb_agg(jsonb_build_object(
   'student_id', s.id, 'name', v2.fn_display_name(s.full_name),
   'student_no', s.student_no, 'class_ar', v2.grade_ar(e.grade)||' — '||e.section,
   'school', sc.name_ar, 'relation', g.relation) order by s.full_name)) end
from v2.guardians g
join v2.students s on s.id=g.student_id
join v2.enrolments e on e.student_id=s.id and e.status='active'
join v2.schools sc on sc.id=e.school_id
where g.user_id = auth.uid() and g.portal_active
$function$
;
