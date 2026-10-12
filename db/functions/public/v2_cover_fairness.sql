-- public.v2_cover_fairness(p_school uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0a9d4d4a14baa9c4328de7789f171d70
CREATE OR REPLACE FUNCTION public.v2_cover_fairness(p_school uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS TABLE("المعلّم" text, "خاناتُ انتظاره" integer, "نصابُه" integer, "تغطياتُه" integer, "آخرُ تغطية" date)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select f.person_ar, f.standby_n, f.teach_n, f.covers_n, f.last_on
  from v2.cover_fairness(p_school, p_term) f
  where v2.my_school(p_school)
$function$
;
