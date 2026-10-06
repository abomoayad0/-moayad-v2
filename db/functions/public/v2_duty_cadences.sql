-- public.v2_duty_cadences()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 18eb93f7664bfc855deec85efe04c387
CREATE OR REPLACE FUNCTION public.v2_duty_cadences()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select jsonb_agg(jsonb_build_object('key',k,'label',k))
  from unnest(array['مستمرّة','شهريّة','فصليّة','سنويّة','عند الحاجة']) k;
$function$
;
