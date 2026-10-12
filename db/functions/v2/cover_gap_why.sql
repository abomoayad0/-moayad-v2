-- v2.cover_gap_why(p_school uuid, p_weekday smallint, p_period smallint, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0f47aba3ac7b27aef540683f040b03d9
CREATE OR REPLACE FUNCTION v2.cover_gap_why(p_school uuid, p_weekday smallint, p_period smallint, p_date date)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select case when count(*) = 0
    then 'لا خانةَ انتظارٍ في هذه الحصّة أصلًا — فالجدولُ نفسُه يحتاج مراجعةً (س-٨-ا-١ سياسة ٠٤)'
    else 'نفد الاحتياط — ' || coalesce(string_agg(distinct c.blocked_ar, ' · '), 'بلا سببٍ معروف') end
  from v2.cover_candidates(p_school, p_weekday, p_period, p_date, null) c;
$function$
;
