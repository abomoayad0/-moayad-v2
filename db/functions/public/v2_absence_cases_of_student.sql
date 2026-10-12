-- public.v2_absence_cases_of_student(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 edca4853f64538f4d794e060852bc414
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
          'days_ar', 'غيابُه '||v2.ar_count(ac.days_count,'يومٌ واحد','يومان','أيّام','يومًا')||
                     case when ac.excused then ' بعذر' else ' بغير عذر' end||
                     case when ac.consecutive then ' متّصلة' else '' end,
          'triggered_ar', v2.fn_to_hijri(ac.triggered_on),
          'status', ac.status,
          'halted', ac.escalation_halted,
          'halt_reason', ac.halt_reason,
          'can_halt', not ac.escalation_halted,
          'can_resume', ac.escalation_halted,
          'open_tasks', (select count(*) from v2.absence_tasks t
                          where t.case_id = ac.id and t.status = 'open'),
          'all_tasks', (select count(*) from v2.absence_tasks t where t.case_id = ac.id),
          'tasks_ar', v2.ar_count0((select count(*) from v2.absence_tasks t
                          where t.case_id = ac.id and t.status = 'open'),
                          'لا مهمّةَ مفتوحة','مهمّةٌ مفتوحةٌ واحدة','مهمّتان مفتوحتان',
                          'مهامَّ مفتوحة','مهمّةً مفتوحة')
                       ||' من '||v2.ar_count((select count(*) from v2.absence_tasks t
                          where t.case_id = ac.id),'مهمّةٍ واحدة','مهمّتين','مهامّ','مهمّة'))
        order by ac.triggered_on desc)
      from v2.absence_cases ac
      where ac.student_id = p_student and (sc is null or ac.school_id = sc)), '[]'::jsonb),
    'note_ar','الوقفُ يمنع إخراجَ الخطابات إلى الجهات · ولا يمنع الإخطارَ ولا الرعاية');
end $function$
;
