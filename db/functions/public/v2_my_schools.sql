-- public.v2_my_schools()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e31f1162e1b62d11c614517d388adff5
CREATE OR REPLACE FUNCTION public.v2_my_schools()
 RETURNS TABLE(id uuid, name_ar text, stage text, students_n integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$ select * from v2.fn_my_schools() $function$
;
