-- v2.external_owner_roles()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3f12c227f681712cab78fe27773fb160
CREATE OR REPLACE FUNCTION v2.external_owner_roles()
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(array_agg(owner_role), '{}'::text[])
    from v2.task_role_map where is_external;
$function$
;
