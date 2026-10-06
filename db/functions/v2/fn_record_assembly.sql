-- v2.fn_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4d2540a729a3003828170e51d0b0c142
CREATE OR REPLACE FUNCTION v2.fn_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint DEFAULT 1, p_by uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_year uuid; v_id uuid; k text; v_role text;
begin
  perform v2.assert_role(array['admin_assistant','info_registrar','duty_officer'],'حصر الغياب في سجل اليوم');
  select e.school_id, e.year_id into v_school, v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  if v_school is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  k := v2.fn_day_kind(v_school,p_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة — نوعه: %', p_date, coalesce(k,'غير معروف'); end if;
  if p_state not in ('attended','missed_inside','late_inside','not_arrived') then
    raise exception 'حالة اصطفاف غير معروفة: %', p_state; end if;
  v_role := coalesce(v2.role_ar(v2.my_role()), 'تشغيل مباشر من محرّر SQL');

  insert into v2.attendance(school_id,year_id,term_no,student_id,on_date,state,assembly_state,recorded_by,recorded_role,source)
  values (v_school,v_year,p_term,p_student,p_date,
          case when p_state='not_arrived' then 'absent' else 'present' end,
          p_state,p_by,v_role,'assistant')
  on conflict (student_id,on_date) do update
    set assembly_state=excluded.assembly_state,
        state = case when excluded.assembly_state='not_arrived'
                     and v2.attendance.arrived_at is null then 'absent' else v2.attendance.state end,
        recorded_by=excluded.recorded_by, recorded_role=excluded.recorded_role
  returning id into v_id;
  return v_id;
end $function$
;
