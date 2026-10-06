-- v2.fn_my_now(p_school uuid, p_at timestamp with time zone)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a18c47e55e17373e4d19f1963c34553f
CREATE OR REPLACE FUNCTION v2.fn_my_now(p_school uuid, p_at timestamp with time zone DEFAULT now())
 RETURNS TABLE(period_no smallint, starts_at time without time zone, ends_at time without time zone, section_label text, subject_ar text, room_ar text, students_n integer, section_id uuid, state text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with d as (select (p_at at time zone 'Asia/Riyadh')::date dd, (p_at at time zone 'Asia/Riyadh')::time tt),
y as (select id from v2.academic_years where school_id=p_school and is_current limit 1)
select ps.period_no, ps.starts_at, ps.ends_at, cs.label_ar, t.subject_ar,
 coalesce(t.room_ar, cs.room_ar),
 (select count(*)::int from v2.enrolments e where e.school_id=p_school and e.status='active'
   and e.grade=cs.grade and e.section=cs.section),
 cs.id,
 case when (select tt from d) between ps.starts_at and ps.ends_at then 'الآن'
      when ps.starts_at > (select tt from d) then 'قادمة' else 'انتهت' end
from v2.timetable t
join v2.period_slots ps on ps.school_id=t.school_id and ps.period_no=t.period_no
join v2.class_sections cs on cs.id=t.section_id
where t.school_id=p_school and t.year_id=(select id from y)
  and t.person_id = v2.current_person()
  and t.weekday = extract(dow from (select dd from d))::smallint
order by ps.period_no;
$function$
;
