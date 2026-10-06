-- public.v2_guardian_me()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 35e41e529d2306426ee61ad30e789166
CREATE OR REPLACE FUNCTION public.v2_guardian_me()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$ select v2.fn_guardian_me() $function$
;
