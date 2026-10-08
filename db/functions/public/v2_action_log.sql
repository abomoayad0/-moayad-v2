-- public.v2_action_log(p_school uuid, p_student uuid, p_limit integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9e6759e6ae86749397100bf98032b19c
CREATE OR REPLACE FUNCTION public.v2_action_log(p_school uuid, p_student uuid, p_limit integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'at',a.at,'action',a.action,'action_ar',a.action_ar,
      'by',a.person_ar,'role',a.role_ar,
      'student',(select v2.fn_display_name(s.full_name) from v2.students s where s.id=a.student_id),
      'detail',a.detail,'is_test',a.is_test) order by a.at desc),'[]'::jsonb)
  into r from (select * from v2.action_log a
    where a.school_id=p_school and (p_student is null or a.student_id=p_student)
    order by a.at desc limit coalesce(p_limit,100)) a;
  return r;
end $function$
;
