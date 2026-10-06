-- v2.fn_period_summary(p_section uuid, p_period smallint, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a63f495f41140c2aaea157d198a35c79
CREATE OR REPLACE FUNCTION v2.fn_period_summary(p_section uuid, p_period smallint, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(enrolled integer, recorded integer, unrecorded integer, present integer, absent integer, late integer, permitted integer, subject_ar text, teacher_ar text, starts_at time without time zone, ends_at time without time zone, is_done boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with l as (select * from v2.fn_period_list(p_section,p_period,p_date))
select count(*)::int,
 count(*) filter (where period_state<>'unrecorded')::int,
 count(*) filter (where period_state='unrecorded')::int,
 count(*) filter (where period_state='present')::int,
 count(*) filter (where period_state='absent')::int,
 count(*) filter (where period_state='late')::int,
 count(*) filter (where period_state='permitted')::int,
 (select tt.subject_ar from v2.timetable tt where tt.section_id=p_section
   and tt.period_no=p_period and tt.weekday=extract(dow from p_date)::smallint limit 1),
 (select v2.fn_display_name(pe.full_name) from v2.timetable tt join v2.people pe on pe.id=tt.person_id
   where tt.section_id=p_section and tt.period_no=p_period
     and tt.weekday=extract(dow from p_date)::smallint limit 1),
 (select ps.starts_at from v2.period_slots ps join v2.class_sections cs on cs.school_id=ps.school_id
   where cs.id=p_section and ps.period_no=p_period),
 (select ps.ends_at from v2.period_slots ps join v2.class_sections cs on cs.school_id=ps.school_id
   where cs.id=p_section and ps.period_no=p_period),
 count(*) filter (where period_state='unrecorded') = 0
from l
$function$
;
