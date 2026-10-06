-- public.v2_enrol_reasons()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b43573510f4c95f5f09b28395403850c
CREATE OR REPLACE FUNCTION public.v2_enrol_reasons()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select jsonb_agg(jsonb_build_object('key',k,'label',v2.enrol_reason_ar(k)))
  from unnest(array['transferred','graduated','withdrawn','deceased',
                    'year_closed','suspended','absent_long','travel','other']) k;
$function$
;
