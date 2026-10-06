-- v2.assert_my_student(p_student uuid, p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c41d0fbe960555f21b11fb2c808fad97
CREATE OR REPLACE FUNCTION v2.assert_my_student(p_student uuid, p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  if auth.uid() is null then return; end if;
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active'
   order by e.created_at desc limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  perform v2.assert_my_school(sc, p_what);
end $function$
;
