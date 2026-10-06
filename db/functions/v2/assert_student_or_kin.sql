-- v2.assert_student_or_kin(p_student uuid, p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 413dab34d71876af10bf2b06d460f226
CREATE OR REPLACE FUNCTION v2.assert_student_or_kin(p_student uuid, p_what text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare who text;
begin
  who := v2.caller_kind(p_student);
  if who in ('student','guardian') then return who; end if;
  perform v2.assert_my_student(p_student, p_what);
  return who;
end $function$
;
