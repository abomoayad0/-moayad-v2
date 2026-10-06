-- v2.is_test_school(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e5dc88d6bc47467f61d1e76fe3187ad7
CREATE OR REPLACE FUNCTION v2.is_test_school(p_school uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce((select test_mode from v2.schools where id = p_school), false)
$function$
;
