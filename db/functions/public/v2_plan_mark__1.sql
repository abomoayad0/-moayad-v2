-- public.v2_plan_mark(p_plan uuid, p_lesson uuid, p_state text, p_why text, p_periods_used smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1a2dfaa616ed0d1c772405f8c7759f63
CREATE OR REPLACE FUNCTION public.v2_plan_mark(p_plan uuid, p_lesson uuid, p_state text, p_why text DEFAULT NULL::text, p_periods_used smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select public.v2_plan_mark(p_plan, p_lesson, p_state, p_why, p_periods_used, null::uuid[]);
$function$
;
