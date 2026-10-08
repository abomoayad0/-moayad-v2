-- v2.task_form_no(p_kind text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 27563615e68b9e990ebaa8b88ab4d5a1
CREATE OR REPLACE FUNCTION v2.task_form_no(p_kind text)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select v2.form_for_kind(p_kind, null);
$function$
;
