-- v2.effective_periods(p_school uuid, p_person uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cf2dabaed9f00d50c6e4e853dd041862
CREATE OR REPLACE FUNCTION v2.effective_periods(p_school uuid, p_person uuid, p_date date)
 RETURNS TABLE(slot uuid, period_no smallint, section_id uuid, subject_ar text, basis text, from_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with wd as (select extract(dow from p_date)::smallint d)
  -- حصصُه التي بقيت له
  select t.id, t.period_no, t.section_id, t.subject_ar, 'schedule'::text, null::text
    from v2.timetable t, wd
   where t.school_id = p_school and t.person_id = p_person and t.weekday = wd.d
     and t.slot_kind in ('teaching','activity')
     and v2.swap_of(p_school, p_date, t.id) is null
  union all
  -- وحصصٌ جاءته بتبديلٍ معتمد · والمادّةُ مادّتُه هو في ذلك الفصل إن كانت له
  select t.id, t.period_no, t.section_id,
         coalesce((select t2.subject_ar from v2.timetable t2
                    where t2.school_id = p_school and t2.person_id = p_person
                      and t2.section_id = t.section_id and t2.slot_kind='teaching'
                    limit 1), t.subject_ar),
         'swap'::text,
         (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id = t.person_id)
    from v2.timetable t, wd
   where t.school_id = p_school and t.weekday = wd.d
     and t.slot_kind in ('teaching','activity')
     and v2.swap_of(p_school, p_date, t.id) = p_person
$function$
;
