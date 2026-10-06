-- v2.fn_record_period(p_student uuid, p_period smallint, p_state text, p_date date, p_minutes smallint, p_note text, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b5eaf14e3f075e8ab6c13ffd309727c9
CREATE OR REPLACE FUNCTION v2.fn_record_period(p_student uuid, p_period smallint, p_state text, p_date date DEFAULT CURRENT_DATE, p_minutes smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text, p_by uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; y uuid; t smallint; k text; v_role text; subj text; tid uuid; day_st text;
begin
  perform v2.assert_my_student(p_student,'رصد حضور الحصة');
  perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher','counselor',
    'deputy_students','deputy','admin_assistant','principal'],'رصد حضور الحصة');
  if p_state not in ('present','absent','late','permitted') then
    raise exception 'حالة غير معروفة: % — والمقبول: حاضر أو غائب أو متأخر أو مستأذن', p_state; end if;

  select e.school_id, e.year_id into sc, y from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  k := v2.fn_day_kind(sc,p_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة — نوعه: %', p_date, coalesce(k,'غير معروف'); end if;
  if not exists (select 1 from v2.period_slots ps where ps.school_id=sc and ps.period_no=p_period) then
    raise exception 'الحصة % غير معرّفة في حصص اليوم', p_period; end if;

  select a.day_status into day_st from v2.attendance a where a.student_id=p_student and a.on_date=p_date;
  if day_st = 'closed' then
    raise exception 'يوم % مقفَل — لا يُعدَّل سجل الحصص فيه إلا بإعادة فتح موثّقة', p_date; end if;

  t := v2.fn_term_of(sc,p_date);
  v_role := coalesce(v2.role_ar(v2.my_role()),'معلم');
  select tt.subject_ar, tt.person_id into subj, tid
   from v2.timetable tt join v2.class_sections cs on cs.id=tt.section_id
   join v2.enrolments e2 on e2.grade=cs.grade and e2.section=cs.section and e2.school_id=cs.school_id
   where e2.student_id=p_student and e2.status='active'
     and tt.period_no=p_period and tt.weekday=extract(dow from p_date)::smallint
     and tt.slot_kind='teaching' limit 1;

  insert into v2.period_attendance(school_id,year_id,term_no,student_id,on_date,period_no,
    subject_ar,teacher_id,state,minutes_late,note,recorded_by,recorded_role)
  values (sc,y,t,p_student,p_date,p_period,subj,coalesce(tid,v2.current_person()),
    p_state,p_minutes,p_note,coalesce(p_by,v2.current_person()),v_role)
  on conflict (student_id,on_date,period_no) do update
    set state=excluded.state, minutes_late=excluded.minutes_late, note=excluded.note,
        recorded_by=excluded.recorded_by, recorded_role=excluded.recorded_role;

  return jsonb_build_object('ok',true,'subject',subj,'state',p_state,'by',v_role,
    'day_state',(select state from v2.attendance where student_id=p_student and on_date=p_date));
end $function$
;
