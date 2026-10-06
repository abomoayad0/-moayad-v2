-- v2.fn_section_timetable(p_section uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5cb4fdbac569d94d8b2618f6d52a9495
CREATE OR REPLACE FUNCTION v2.fn_section_timetable(p_section uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS TABLE(weekday smallint, weekday_ar text, period_no smallint, starts_at time without time zone, ends_at time without time zone, subject_ar text, teacher text, room_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select t.weekday, t.weekday_ar, t.period_no, ps.starts_at, ps.ends_at, t.subject_ar,
    coalesce(v2.fn_display_name(p.full_name),'— لم يُسنَد'), coalesce(t.room_ar, cs.room_ar)
  from v2.timetable t
  join v2.class_sections cs on cs.id=t.section_id
  join v2.period_slots ps on ps.school_id=t.school_id and ps.period_no=t.period_no
  left join v2.people p on p.id=t.person_id
  where t.section_id=p_section and (p_term is null or t.term_no is not distinct from p_term)
  order by t.weekday, t.period_no
$function$
;
