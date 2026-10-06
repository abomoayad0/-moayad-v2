-- public.v2_act_as(p_role text, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 326720bc8609155bb8785210240a3204
CREATE OR REPLACE FUNCTION public.v2_act_as(p_role text, p_school uuid DEFAULT NULL::uuid)
 RETURNS text
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$ select v2.fn_act_as(p_role,p_school) $function$
;
