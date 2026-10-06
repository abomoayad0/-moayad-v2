-- v2.assert_my_child(p_student uuid, p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4dda7491bab9f1876cfe2a26642da8bb
CREATE OR REPLACE FUNCTION v2.assert_my_child(p_student uuid, p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if auth.uid() is null then return; end if;
  if not exists (select 1 from v2.guardians g
                 where g.user_id=auth.uid() and g.portal_active and g.student_id=p_student) then
    raise exception 'هذا الطالب ليس من أبنائك — لا يُقبل %', p_what; end if;
end $function$
;
