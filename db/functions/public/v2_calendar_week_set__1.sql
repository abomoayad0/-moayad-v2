-- public.v2_calendar_week_set(p_school uuid, p_term smallint, p_week smallint, p_from date, p_to date, p_is_exam boolean, p_reason text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6ffc250da2b44b8311a0f65000ba79df
CREATE OR REPLACE FUNCTION public.v2_calendar_week_set(p_school uuid, p_term smallint, p_week smallint, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date, p_is_exam boolean DEFAULT NULL::boolean, p_reason text DEFAULT NULL::text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select public.v2_calendar_week_set(p_school, p_term, p_week, p_from, p_to,
                                     p_is_exam, p_reason, p_note, 'school');
$function$
;
