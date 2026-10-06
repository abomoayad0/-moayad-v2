-- public.v2_weekday(p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3d91f368bf3513d266ab21fe02e9fa70
CREATE OR REPLACE FUNCTION public.v2_weekday(p_date date)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce((select d.weekday_ar from v2.calendar_days d where d.on_g=p_date limit 1),
    case extract(dow from p_date)::int when 0 then 'الأحد' when 1 then 'الاثنين'
      when 2 then 'الثلاثاء' when 3 then 'الأربعاء' when 4 then 'الخميس'
      when 5 then 'الجمعة' else 'السبت' end)
$function$
;
