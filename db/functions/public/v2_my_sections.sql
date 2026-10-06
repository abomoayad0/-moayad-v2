-- public.v2_my_sections(p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 539b6e77482509337ee7f34d12b4c2c9
CREATE OR REPLACE FUNCTION public.v2_my_sections(p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(section_id uuid, class_ar text, period_no smallint, starts_at time without time zone, ends_at time without time zone, subject_ar text, state text, students_n integer, recorded_n integer, is_done boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with d as (select (now() at time zone 'Asia/Riyadh')::time tt)
select cs.id, cs.label_ar, ps.period_no, ps.starts_at, ps.ends_at, t.subject_ar,
 case when (select tt from d) between ps.starts_at and ps.ends_at then 'الآن'
      when ps.starts_at > (select tt from d) then 'قادمة' else 'انتهت' end,
 (select count(*)::int from v2.enrolments e where e.school_id=cs.school_id
   and e.grade=cs.grade and e.section=cs.section and e.status='active'),
 (select count(*)::int from v2.period_attendance pa join v2.enrolments e2 on e2.student_id=pa.student_id
   where pa.on_date=p_date and pa.period_no=ps.period_no and e2.school_id=cs.school_id
     and e2.grade=cs.grade and e2.section=cs.section and e2.status='active'),
 (select count(*) from v2.enrolments e3 where e3.school_id=cs.school_id and e3.grade=cs.grade
    and e3.section=cs.section and e3.status='active')
 = (select count(*) from v2.period_attendance pa2 join v2.enrolments e4 on e4.student_id=pa2.student_id
    where pa2.on_date=p_date and pa2.period_no=ps.period_no and e4.school_id=cs.school_id
      and e4.grade=cs.grade and e4.section=cs.section and e4.status='active')
from v2.timetable t
join v2.class_sections cs on cs.id=t.section_id
join v2.period_slots ps on ps.school_id=t.school_id and ps.period_no=t.period_no
where t.person_id = v2.current_person() and t.slot_kind='teaching'
  and t.weekday = extract(dow from p_date)::smallint
order by ps.period_no
$function$
;
