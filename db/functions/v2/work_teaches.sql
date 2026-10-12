-- v2.work_teaches(p_person uuid, p_section uuid, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ebbd31be91fa1d59e9250cabbca3ba40
CREATE OR REPLACE FUNCTION v2.work_teaches(p_person uuid, p_section uuid, p_subject text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select exists (
    select 1 from v2.timetable t
     where t.person_id = p_person
       and t.section_id = p_section
       and t.subject_ar = p_subject
       and t.slot_kind in ('teaching','activity'))
      or exists (
    select 1 from v2.effective_periods(
             (select school_id from v2.class_sections where id = p_section),
             p_person, current_date) e
     where e.section_id = p_section and e.subject_ar = p_subject);
$function$
;
