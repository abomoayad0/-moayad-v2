-- public.v2_guardian_reply(p_student uuid, p_event uuid, p_kind text, p_reply text, p_note text, p_suggested date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c5c2848a1419150415f34e542e7074c3
CREATE OR REPLACE FUNCTION public.v2_guardian_reply(p_student uuid, p_event uuid, p_kind text, p_reply text, p_note text, p_suggested date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare who text; sc uuid; gid uuid; nid uuid;
begin
  who := v2.caller_kind(p_student);
  if who <> 'guardian' then
    raise exception 'ردُّ وليّ الأمر يكتبه هو من بوّابته — ولا تملؤه المدرسة'; end if;
  if p_kind not in ('دعوة','خطة','إشعار') then raise exception 'نوعٌ غيرُ معروف'; end if;
  if p_reply not in ('أحضر','أعتذر وأقترح موعدًا','لا أستطيع') then
    raise exception 'الردّ: أحضر · أعتذر وأقترح موعدًا · لا أستطيع'; end if;
  if p_reply='أعتذر وأقترح موعدًا' and p_suggested is null then
    raise exception 'اقترح موعدًا'; end if;
  if p_reply='لا أستطيع' and btrim(coalesce(p_note,''))='' then
    raise exception 'اكتب سببَك'; end if;

  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  select id into gid from v2.guardians
   where student_id=p_student and user_id=auth.uid() limit 1;

  insert into v2.guardian_replies(school_id,student_id,event_id,kind,reply,
      note_ar,suggested,by_guardian)
  values (sc,p_student,p_event,p_kind,p_reply,
      nullif(btrim(coalesce(p_note,'')),''),p_suggested,gid)
  returning id into nid;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (sc,'other',current_date,p_student,'ردّ وليُّ الأمر',
      p_reply||coalesce(' — '||btrim(p_note),'')||
      coalesce(' · يقترح '||p_suggested::text,''),
      'guardian_replies',nid,'all',
      coalesce((select test_mode from v2.schools where id=sc),false));
  return jsonb_build_object('ok',true,'reply',nid,'note','وصل ردُّك إلى المدرسة');
end $function$
;
