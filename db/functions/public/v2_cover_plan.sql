-- public.v2_cover_plan(p_school uuid, p_weekday smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2ad3b250d52aeac41214e0b6fe633f14
CREATE OR REPLACE FUNCTION public.v2_cover_plan(p_school uuid, p_weekday smallint)
 RETURNS TABLE("الحصّة" smallint, "الترتيب" integer, "المعلّم" text, "الأساس" text, "تغطياته" integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select p.period_no, p.ord, p.person_ar,
    case p.basis when 'standby' then 'احتياطٌ معتمد' else 'فارغٌ بإذن المدرسة' end,
    p.covers_term
  from v2.cover_plan(p_school, p_weekday) p
  where v2.my_school(p_school)
$function$
;
