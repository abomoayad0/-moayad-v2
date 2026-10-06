-- v2.fn_period_list(p_section uuid, p_period smallint, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5b4fcd04e396b6f1feef9609f653f55a
CREATE OR REPLACE FUNCTION v2.fn_period_list(p_section uuid, p_period smallint, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(student_id uuid, student_no text, display_name text, class_ar text, day_state text, day_state_ar text, period_state text, period_state_ar text, minutes_late smallint, note text, day_status text, practices_today integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select s.id, s.student_no, v2.fn_display_name(s.full_name),
 v2.grade_ar(e.grade)||' — '||e.section,
 coalesce(a.state,'unrecorded'),
 case coalesce(a.state,'unrecorded') when 'absent' then 'غائب عن اليوم' when 'late' then 'متأخر'
      when 'permitted' then 'مستأذن' when 'present' then 'حاضر' else 'لم يُرصد في سجل اليوم' end,
 coalesce(pa.state,'unrecorded'),
 case coalesce(pa.state,'unrecorded') when 'present' then 'حاضر الحصة'
      when 'absent' then 'غائب عن الحصة' when 'late' then 'متأخر عن الحصة'
      when 'permitted' then 'مستأذن من الحصة' else 'لم يُرصد بعد' end,
 pa.minutes_late, pa.note, coalesce(a.day_status,'unrecorded'),
 (select count(*)::int from v2.practice_records r
   where r.student_id=s.id and r.on_date=p_date and r.undone_at is null)
from v2.class_sections cs
join v2.enrolments e on e.school_id=cs.school_id and e.grade=cs.grade and e.section=cs.section and e.status='active'
join v2.students s on s.id=e.student_id
left join v2.attendance a on a.student_id=s.id and a.on_date=p_date
left join v2.period_attendance pa on pa.student_id=s.id and pa.on_date=p_date and pa.period_no=p_period
where cs.id=p_section
order by s.student_no
$function$
;
