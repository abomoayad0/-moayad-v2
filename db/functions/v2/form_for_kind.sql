-- v2.form_for_kind(p_kind text, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 99787ff9d294de524c37d8c99fe5af40
CREATE OR REPLACE FUNCTION v2.form_for_kind(p_kind text, p_school uuid DEFAULT NULL::uuid)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select f.form_no from v2.task_kind_forms f
   where f.kind = p_kind
     and (f.school_id is null or f.school_id = p_school)
   order by (f.school_id is null) limit 1;
$function$
;
