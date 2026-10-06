-- v2.current_tenant()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e917325845dad2e1ad2a7358dcc48f3e
CREATE OR REPLACE FUNCTION v2.current_tenant()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select tenant_id from v2.app_users where id = auth.uid() and is_active
$function$
;
