-- v2.my_grant()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4b05b1b4d41fb7060defebb7701db7bf
CREATE OR REPLACE FUNCTION v2.my_grant()
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select role from v2.app_users where id = auth.uid() and is_active limit 1
$function$
;
