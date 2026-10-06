-- v2.fn_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text, p_term smallint, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a3fc09fb40777eba45b9da844fa98e3a
CREATE OR REPLACE FUNCTION v2.fn_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text DEFAULT NULL::text, p_term smallint DEFAULT 1, p_by uuid DEFAULT NULL::uuid)
 RETURNS TABLE("الدقائق" integer, "العتبة" text, "الإجراء" text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_year uuid; st record; mins int; v_th text; k text; v_ev uuid; g record; v_act text; v_role text;
begin
  perform v2.assert_role(array['duty_officer','admin_assistant','admin_assistant_students','guard'],
    'رصد تأخر الانصراف');
  select e.school_id, e.year_id into v_school, v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  if v_school is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  k := v2.fn_day_kind(v_school,p_date);
  if k is null or k not in ('study','exam') then raise exception 'اليوم % ليس يوم دراسة', p_date; end if;
  v_role := coalesce(v2.role_ar(v2.my_role()),'المناوب');

  select * into st from v2.dismissal_settings where school_id=v_school;
  mins := (extract(epoch from (p_left - st.dismiss_at))/60)::int;
  if mins < st.census_after_min then
    raise exception 'التأخر % دقيقة دون عتبة الحصر (% دقيقة) — لا يُرصد', mins, st.census_after_min; end if;
  v_th := case when mins >= st.action_after_min then 'action_30' else 'census_15' end;
  v_act := case when v_th='action_30'
    then 'يُتخذ الإجراء المناسب بناء على قواعد العمل — ض06 من س-6-ا1'
    else 'حصر فقط — ض03 من س-6-ا1' end;

  insert into v2.dismissal_records(school_id,year_id,term_no,student_id,on_date,left_at,
      minutes_after,threshold,reason_ar,recorded_by,recorded_role,action_taken)
  values (v_school,v_year,p_term,p_student,p_date,p_left,mins,v_th,p_reason,
          coalesce(p_by,v2.current_person()),v_role,v_act)
  on conflict (student_id,on_date) do update
    set left_at=excluded.left_at, minutes_after=excluded.minutes_after,
        threshold=excluded.threshold, reason_ar=excluded.reason_ar,
        recorded_role=excluded.recorded_role, action_taken=excluded.action_taken;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,needs_action,action_ar)
  values (v_school,'other',p_date,p_student,'تأخر عن الانصراف',
    'بقي ابنكم في المدرسة بعد نهاية الدوام '||mins||' دقيقة.'||
    case when v_th='action_30' then ' وقد تجاوز الحد الذي يستوجب اتخاذ إجراء — ض06.' else '' end,
    v_th='action_30', case when v_th='action_30' then 'اتخاذ الإجراء المناسب بناء على قواعد العمل' else null end)
  returning id into v_ev;
  for g in select id from v2.guardians where student_id=p_student loop
    insert into v2.event_deliveries(event_id,channel,to_guardian) values (v_ev,'guardian_portal',g.id),(v_ev,'whatsapp',g.id);
  end loop;
  update v2.dismissal_records set guardian_notified=true where student_id=p_student and on_date=p_date;
  return query select mins, case v_th when 'action_30' then 'تجاوز 30 دقيقة' else 'بين 15 و30 دقيقة' end, v_act;
end $function$
;
