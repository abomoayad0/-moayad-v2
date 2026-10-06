-- v2.fn_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text, p_term smallint, p_by uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7f4e5fb6fc92bf48531626e16dab52ef
CREATE OR REPLACE FUNCTION v2.fn_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text DEFAULT 'enter_class'::text, p_term smallint DEFAULT 1, p_by uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_year uuid; st record; mins int; v_permit uuid; k text; v_role text;
begin
  perform v2.assert_role(array['duty_officer','admin_assistant','admin_assistant_students','info_registrar'],
    'تسجيل الوصول المتأخر وإصدار إذن الموافقة');
  if p_decision not in ('enter_class','to_counselor') then
    raise exception 'قرار غير معروف: % — والمنصوص: دخول الفصل بإذن الموافقة أو التحويل للموجه الطلابي (ض05)', p_decision; end if;
  select e.school_id, e.year_id into v_school, v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  if v_school is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  k := v2.fn_day_kind(v_school,p_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة — نوعه: %', p_date, coalesce(k,'غير معروف'); end if;
  if exists (select 1 from v2.day_closures c where c.school_id=v_school and c.on_date=p_date and c.reopened_at is null) then
    raise exception 'يوم % مقفَل — لا يُسجَّل فيه وصول إلا بإعادة فتح موثّقة بسبب مكتوب', p_date; end if;

  v_role := coalesce(v2.role_ar(v2.my_role()),'المناوب');
  select * into st from v2.day_settings where school_id=v_school;
  mins := greatest(0, (extract(epoch from (p_arrived - st.assembly_at))/60)::int - st.late_grace_min);
  insert into v2.entry_permits(school_id,student_id,on_date,arrived_at,minutes_late,decision,issued_by,note)
  values (v_school,p_student,p_date,p_arrived,mins,p_decision,coalesce(p_by,v2.current_person()),p_note)
  on conflict (student_id,on_date) do update
    set arrived_at=excluded.arrived_at, minutes_late=excluded.minutes_late,
        decision=excluded.decision, issued_by=excluded.issued_by, note=excluded.note
  returning id into v_permit;
  insert into v2.attendance(school_id,year_id,term_no,student_id,on_date,state,assembly_state,
                            arrived_at,minutes_from_assembly,permit_id,recorded_by,recorded_role,source)
  values (v_school,v_year,p_term,p_student,p_date,'late','not_arrived',p_arrived,mins,v_permit,
          coalesce(p_by,v2.current_person()),v_role,'assistant')
  on conflict (student_id,on_date) do update
    set state='late', arrived_at=excluded.arrived_at,
        minutes_from_assembly=excluded.minutes_from_assembly, permit_id=excluded.permit_id,
        late_recorded_role=v_role;
  update v2.event_deliveries d set status='cancelled',
    cancel_reason='حضر الطالب بعد الإشعار المبدئي في الساعة '||p_arrived
   from v2.events e
   where d.event_id=e.id and e.kind='absence_prenotice'
     and e.student_id=p_student and e.on_date=p_date and d.status in ('queued','sent','delivered');
  return v_permit;
end $function$
;
