-- public.v2_practices(p_scope text, p_polarity text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 11d3bddf5036de76316497cac38614b2
CREATE OR REPLACE FUNCTION public.v2_practices(p_scope text DEFAULT NULL::text, p_polarity text DEFAULT NULL::text)
 RETURNS TABLE(code text, polarity text, title_ar text, points numeric, scope text, zone text, threshold_count smallint, threshold_days smallint, once_per_day boolean, escalate_note text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select c.code,c.polarity,c.title_ar,c.points,c.scope,c.zone,
         c.threshold_count,c.threshold_days,c.once_per_day,c.escalate_note
  from v2.class_practices c where c.active
   and (p_scope is null or c.scope=p_scope) and (p_polarity is null or c.polarity=p_polarity)
  order by c.polarity desc, c.ord
$function$
;
