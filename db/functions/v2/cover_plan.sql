-- v2.cover_plan(p_school uuid, p_weekday smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3f1a4f2509b78675a40db6652a0a9163
CREATE OR REPLACE FUNCTION v2.cover_plan(p_school uuid, p_weekday smallint)
 RETURNS TABLE(period_no smallint, ord integer, person_ar text, basis text, covers_term integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select pp.period_no, c.ord, c.person_ar, c.basis, c.covers_term
  from (select distinct t.period_no from v2.timetable t
         where t.school_id = p_school and t.weekday = p_weekday and t.slot_kind = 'standby') pp
  cross join lateral v2.cover_candidates(p_school, p_weekday, pp.period_no, null, null) c
  where c.blocked_ar is null and c.ord <= 5
  order by pp.period_no, c.ord
$function$
;
