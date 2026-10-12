-- public.v2_absence_cases_of_student(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6026fcb35b528be29589046c6f1208c8
CREATE OR REPLACE FUNCTION public.v2_absence_cases_of_student(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  perform v2.assert_my_student(p_student, 'حالاتِ غياب الطالب');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant','admin_assistant_students','counselor'],
      'حالاتِ غياب الطالب');
  select e.school_id into sc from v2.enrolments e
   where e.student_id = p_student and e.status='active' limit 1;

  return jsonb_build_object(
    'student', (select v2.fn_display_name(full_name) from v2.students where id = p_student),
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object(
          'case', ac.id,
          'days', ac.days_count, 'excused', ac.excused, 'consecutive', ac.consecutive,
          'triggered_ar', v2.fn_to_hijri(ac.triggered_on),
          'status', ac.status,
          'halted', ac.escalation_halted,
          'halt_reason', ac.halt_reason,
          'can_halt', not ac.escalation_halted,
          'can_resume', ac.escalation_halted,
          'open_tasks', (select count(*) from v2.absence_tasks t
                          where t.case_id = ac.id and t.status = 'open'),
          'all_tasks', (select count(*) from v2.absence_tasks t where t.case_id = ac.id))
        order by ac.triggered_on desc)
      from v2.absence_cases ac
      where ac.student_id = p_student and (sc is null or ac.school_id = sc)), '[]'::jsonb),
    'note_ar','الوقفُ يمنع إخراجَ الخطابات إلى الجهات · ولا يمنع الإخطارَ ولا الرعاية');
end $function$
;
