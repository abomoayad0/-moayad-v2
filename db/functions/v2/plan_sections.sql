-- v2.plan_sections(p_plan uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 eac4982c92a711a4d3a423b3d1d15930
CREATE OR REPLACE FUNCTION v2.plan_sections(p_plan uuid)
 RETURNS TABLE(section_id uuid, label_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select distinct c.id, coalesce(c.label_ar, c.grade::text||'/'||c.section)
  from v2.lesson_plans p
  join v2.class_sections c
    on c.school_id = p.school_id and c.grade = p.grade and c.active
  join v2.timetable t
    on t.school_id = p.school_id and t.section_id = c.id
   and t.subject_ar = p.subject_ar and t.slot_kind = 'teaching'
   and (p.owner_person is null or t.person_id = p.owner_person)
  where p.id = p_plan
  order by 2
$function$
;
