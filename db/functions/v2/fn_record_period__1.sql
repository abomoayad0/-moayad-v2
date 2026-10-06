-- v2.fn_record_period(p_student uuid, p_date date, p_period smallint, p_state text, p_subject text, p_teacher uuid, p_minutes_late smallint, p_term smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dd8d23bb874c7ae9a4ee5eff26e88c88
CREATE OR REPLACE FUNCTION v2.fn_record_period(p_student uuid, p_date date, p_period smallint, p_state text, p_subject text DEFAULT NULL::text, p_teacher uuid DEFAULT NULL::uuid, p_minutes_late smallint DEFAULT NULL::smallint, p_term smallint DEFAULT 1, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_year uuid; v_id uuid; v_permit uuid; v_state text := p_state;
begin
  select e.school_id, e.year_id into v_school, v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  if v_school is null then raise exception 'الطالب لا قيد فعّال له'; end if;

  -- إذن الموافقة يفرّق بين المتأخر والهارب
  select id into v_permit from v2.entry_permits
   where student_id=p_student and on_date=p_date and decision='enter_class';
  if v_permit is not null and p_state='absent' then v_state := 'entered_with_permit'; end if;

  insert into v2.period_attendance(school_id,year_id,term_no,student_id,on_date,period_no,
          subject_ar,teacher_id,state,minutes_late,note)
  values (v_school,v_year,p_term,p_student,p_date,p_period,p_subject,p_teacher,v_state,p_minutes_late,p_note)
  on conflict (student_id,on_date,period_no) do update
    set state=excluded.state, minutes_late=excluded.minutes_late,
        subject_ar=excluded.subject_ar, teacher_id=excluded.teacher_id, note=excluded.note
  returning id into v_id;
  return v_id;
end $function$
;
