-- v2.conduct_mode_of(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7cf8c79f71913d757ac5a04cb08ff6b8
CREATE OR REPLACE FUNCTION v2.conduct_mode_of(p_school uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select r.teaching_mode from v2.conduct_school_rules r where r.school_id = p_school;
$function$
;
