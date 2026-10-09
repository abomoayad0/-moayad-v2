-- v2.teacher_context_roles()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b00569b3f5a4c14135c2691f8cfef257
CREATE OR REPLACE FUNCTION v2.teacher_context_roles()
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(array_agg(owner_role), '{}'::text[])
    from v2.task_role_map where needs_context = 'record_teacher';
$function$
;
