-- public.v2_me()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2e2815007ce065118b7073ad345d099a
CREATE OR REPLACE FUNCTION public.v2_me()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$ select v2.fn_me() $function$
;
