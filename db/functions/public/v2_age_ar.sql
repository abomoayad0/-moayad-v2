-- public.v2_age_ar(p_birth date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a1847143f699cad1688285c8d03b9e49
CREATE OR REPLACE FUNCTION public.v2_age_ar(p_birth date)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select case when p_birth is null then null else
 (extract(year from age(current_date,p_birth))::int)::text||' سنة'||
 case when extract(month from age(current_date,p_birth))::int > 0
   then ' و'||(extract(month from age(current_date,p_birth))::int)::text||' شهرًا' else '' end end
$function$
;
