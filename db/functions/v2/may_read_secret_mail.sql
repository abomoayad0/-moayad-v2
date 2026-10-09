-- v2.may_read_secret_mail()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 300266906ca0b64120623292d27469c4
CREATE OR REPLACE FUNCTION v2.may_read_secret_mail()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select v2.my_grant() in ('owner','admin') or v2.my_role() in ('principal','deputy');
$function$
;
