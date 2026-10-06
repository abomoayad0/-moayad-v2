-- v2.fn_day_list(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ad0360840a738fdc7593a181631e7f9c
CREATE OR REPLACE FUNCTION v2.fn_day_list(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(student_id uuid, student_no text, full_name text, display_name text, grade smallint, section text, state text, state_ar text, assembly_state text, assembly_ar text, arrived_at time without time zone, minutes_late smallint, recorded_role text, source text, day_status text, has_permit boolean, permit_decision text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select s.id, s.student_no, s.full_name, v2.fn_display_name(s.full_name),
  e.grade, e.section,
  coalesce(a.state,'unrecorded'),
  case coalesce(a.state,'unrecorded')
    when 'absent' then 'غياب' when 'late' then 'تأخر'
    when 'permitted' then 'استئذان' when 'present' then 'حاضر'
    else 'لم يُرصد بعد' end,
  a.assembly_state,
  case a.assembly_state
    when 'attended' then 'حضر الاصطفاف'
    when 'missed_inside' then 'في المدرسة ولم يحضر الاصطفاف'
    when 'late_inside' then 'تأخر عن الاصطفاف'
    when 'not_arrived' then 'لم يصل'
    else null end,
  a.arrived_at, a.minutes_from_assembly, a.recorded_role, a.source,
  coalesce(a.day_status,'unrecorded'),
  (p.id is not null), p.decision
from v2.enrolments e
join v2.students s on s.id = e.student_id
left join v2.attendance a on a.student_id = s.id and a.on_date = p_date
left join v2.entry_permits p on p.student_id = s.id and p.on_date = p_date
where e.school_id = p_school and e.status = 'active'
order by e.grade, e.section, s.student_no;
$function$
;
