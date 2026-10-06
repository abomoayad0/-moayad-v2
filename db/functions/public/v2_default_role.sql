-- public.v2_default_role()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 111fe6841d4d4ed3cecc16e371033273
CREATE OR REPLACE FUNCTION public.v2_default_role()
 RETURNS text
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$ select v2.fn_default_role() $function$
;
