-- v2.assert_my_student(p_student uuid, p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9b22599070370735d0f0b0e463ca8e0e
CREATE OR REPLACE FUNCTION v2.assert_my_student(p_student uuid, p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; who text;
begin
  if auth.uid() is null then return; end if;
  who := v2.caller_kind(p_student);
  if who in ('student','guardian') then return; end if;
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active'
   order by e.created_at desc limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  perform v2.assert_my_school(sc, p_what);
end $function$
;
