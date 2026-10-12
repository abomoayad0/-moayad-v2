-- v2.health_gate(p_school uuid, p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 95d8818f9219353ace4745b54f127fff
CREATE OR REPLACE FUNCTION v2.health_gate(p_school uuid, p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE
AS $function$
begin
  perform v2.assert_role(array['health_counselor'], p_what);
  if not v2.my_school(p_school) then raise exception 'ليست مدرستَك'; end if;
end $function$
;
