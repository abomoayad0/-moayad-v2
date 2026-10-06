-- public.v2_guardian_child(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 755341474cfc7eef4e05117316f9f537
CREATE OR REPLACE FUNCTION public.v2_guardian_child(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare y uuid;
begin
  perform v2.assert_my_child(p_student,'الاطّلاع على سجل ابنك');
  select year_id into y from v2.enrolments where student_id=p_student and status='active' limit 1;
  return jsonb_build_object(
   'student', (select jsonb_build_object('name', v2.fn_display_name(s.full_name),
      'student_no', s.student_no, 'class_ar', v2.grade_ar(e.grade)||' — '||e.section,
      'school', sc.name_ar)
     from v2.students s join v2.enrolments e on e.student_id=s.id and e.status='active'
     join v2.schools sc on sc.id=e.school_id where s.id=p_student),
   'attendance', (select to_jsonb(z) from v2.fn_attendance_state(p_student,y) z),
   'absences', coalesce((select jsonb_agg(jsonb_build_object(
       'on_h', v2.fn_to_hijri(a.on_date), 'on_g', a.on_date,
       'weekday_ar', (select d.weekday_ar from v2.calendar_days d where d.on_g=a.on_date limit 1),
       'state_ar', case a.state when 'absent' then 'غياب' when 'late' then 'تأخر' else a.state end,
       'excused', v2.fn_is_excused(a.student_id,a.on_date)) order by a.on_date desc)
     from v2.attendance a where a.student_id=p_student and a.state in ('absent','late')),'[]'::jsonb),
   'notices', coalesce((select jsonb_agg(jsonb_build_object(
       'on_h', v2.fn_to_hijri(ev.on_date), 'title', ev.title_ar, 'body', ev.body_ar,
       'needs_action', ev.needs_action, 'action', ev.action_ar,
       'read_at', d.read_at) order by ev.on_date desc)
     from v2.events ev join v2.event_deliveries d on d.event_id=ev.id
     where ev.student_id=p_student and d.channel='guardian_portal'
       and d.to_guardian in (select id from v2.guardians where user_id=auth.uid())),'[]'::jsonb),
   'excuses', coalesce((select jsonb_agg(jsonb_build_object(
       'id', c.id, 'from_h', v2.fn_to_hijri(c.from_date), 'to_h', v2.fn_to_hijri(c.to_date),
       'submitted_h', v2.fn_to_hijri(c.submitted_on), 'reason', c.reason_text,
       'attachment', c.attachment_name, 'decision', c.decision,
       'decision_ar', case c.decision when 'pending' then 'قيد النظر'
          when 'accepted' then 'قُبل' when 'rejected' then 'رُدّ' else c.decision end,
       'note', c.decision_note, 'verdict', c.window_verdict) order by c.from_date desc)
     from v2.absence_excuse_claims c where c.student_id=p_student),'[]'::jsonb));
end $function$
;
