-- public.v2_students_board(p_school uuid, p_grade smallint, p_section text, p_q text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6f4dba74333ffeddfda242655579c4af
CREATE OR REPLACE FUNCTION public.v2_students_board(p_school uuid, p_grade smallint, p_section text, p_q text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select public.v2_students_board(p_school, p_grade, p_section, p_q, 500) -> 'rows';
$function$
;
