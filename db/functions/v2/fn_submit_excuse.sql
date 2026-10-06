-- v2.fn_submit_excuse(p_student uuid, p_from date, p_to date, p_by text, p_channel text, p_excuse_item smallint, p_reason text, p_attachment text, p_attachment_name text, p_submitted date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 56db97ba27c78aa4c039f1518f887432
CREATE OR REPLACE FUNCTION v2.fn_submit_excuse(p_student uuid, p_from date, p_to date, p_by text DEFAULT 'guardian'::text, p_channel text DEFAULT 'guardian_portal'::text, p_excuse_item smallint DEFAULT NULL::smallint, p_reason text DEFAULT NULL::text, p_attachment text DEFAULT NULL::text, p_attachment_name text DEFAULT NULL::text, p_submitted date DEFAULT NULL::date)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_id uuid; w record; v_sub date := coalesce(p_submitted, current_date); v_ev uuid;
begin
  select school_id into v_school from v2.students where id=p_student;
  if v_school is null then raise exception 'الطالب غير موجود'; end if;

  select * into w from v2.fn_excuse_window(v_school, p_from, v_sub);

  insert into v2.absence_excuse_claims(school_id,student_id,from_date,to_date,excuse_item,reason_text,
      submitted_by,submitted_on,channel,proof_ref,attachment_ref,attachment_name,
      limit3_on,limit10_on,working_days_used,window_verdict,decision)
  values (v_school,p_student,p_from,p_to,p_excuse_item,p_reason,
      case when p_by='guardian' then 'guardian' else 'student' end, v_sub, p_channel,
      p_attachment_name, p_attachment, p_attachment_name,
      w.حدّ_الثلاثة, w.حدّ_العشرة, w.أيام_العمل_المستغرقة, w.الحكم, 'pending')
  returning id into v_id;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,ref_table,ref_id,needs_action,action_ar)
  values (v_school,'excuse_submitted',v_sub,p_student,'عذر غياب مقدَّم',
    'قُدّم عذر عن الغياب من '||p_from||' إلى '||p_to||
    case when p_attachment is null then ' — بلا مرفق' else ' — ومعه مرفق: '||coalesce(p_attachment_name,'ملف') end||
    '. وحكم المهلة: '||w.الحكم,
    'absence_excuse_claims',v_id,true,'البتّ في العذر: قبول أو ردّ بسبب') returning id into v_ev;
  insert into v2.event_deliveries(event_id,channel,to_role) values (v_ev,'staff_inbox','وكيل شؤون الطلبة');
  update v2.absence_excuse_claims set event_id=v_ev where id=v_id;
  return v_id;
end $function$
;
