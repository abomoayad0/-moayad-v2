-- public.v2_my_roles()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5e0eafc24dafbf0c8554bf1e29ac5845
CREATE OR REPLACE FUNCTION public.v2_my_roles()
 RETURNS TABLE(role_key text, role_ar text, source text, school_id uuid, school_ar text, is_current boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$ select * from v2.fn_my_roles() $function$
;
