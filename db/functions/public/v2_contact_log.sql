-- public.v2_contact_log(p_student uuid, p_task uuid, p_channel text, p_outcome text, p_summary text, p_guardian_say text, p_at time without time zone, p_right_number text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 31a82efd54264aa33858da0ee9b7105c
CREATE OR REPLACE FUNCTION public.v2_contact_log(p_student uuid, p_task uuid, p_channel text, p_outcome text, p_summary text, p_guardian_say text, p_at time without time zone, p_right_number text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; gid uuid; rid uuid; n smallint; nid uuid; t record; closed boolean := false;
begin
  perform v2.assert_role(array['deputy_students','deputy','principal','counselor',
      'admin_assistant','admin_assistant_students'],'إثباتَ الاتّصال بوليّ الأمر');
  perform v2.assert_my_student(p_student,'إثبات الاتصال');
  if p_channel is null or btrim(p_channel)='' then
    raise exception 'اختر وسيلةَ الاتّصال: هاتفٌ · رسالةٌ · حضورٌ · بوّابة'; end if;
  if p_channel not in ('هاتف','رسالة','حضور','بوّابة') then
    raise exception 'وسيلةُ الاتّصال: هاتفٌ · رسالةٌ · حضورٌ · بوّابة'; end if;
  if p_outcome is null or btrim(p_outcome)='' then
    raise exception 'اختر نتيجةَ الاتّصال'; end if;
  if p_outcome not in ('ردّ وعلم','ردّ ورفض','لم يردّ','الرقم مغلق','الرقم خطأ') then
    raise exception 'نتيجةُ الاتّصال: ردّ وعلم · ردّ ورفض · لم يردّ · الرقم مغلق · الرقم خطأ'; end if;

  -- 🔑 الحقلُ يتبع النتيجة
  if p_outcome in ('ردّ وعلم','ردّ ورفض') and btrim(coalesce(p_summary,''))='' then
    raise exception 'اكتب ما دار في الاتّصال — فقد ردّ وليُّ الأمر'; end if;
  if p_outcome = 'ردّ ورفض' and btrim(coalesce(p_guardian_say,''))='' then
    raise exception 'اكتب ما قاله وليُّ الأمر — فرفضُه حجّةٌ تُقيَّد'; end if;
  if p_outcome = 'لم يردّ' and p_at is null then
    raise exception 'اكتب ساعةَ المحاولة — فمن لم يردّ يُقيَّد وقتُ طلبه'; end if;
  if p_outcome = 'الرقم خطأ' and btrim(coalesce(p_right_number,''))='' then
    raise exception 'اكتب الرقمَ الصحيحَ إن عرفتَه، أو «لا يُعرف»'; end if;

  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  select id into gid from v2.guardians where student_id=p_student and is_primary limit 1;
  if gid is null then select id into gid from v2.guardians where student_id=p_student limit 1; end if;
  if gid is null then raise exception 'لا وليَّ أمرٍ مسجَّلٌ لهذا الطالب'; end if;

  if p_task is not null then
    select * into t from v2.behavior_tasks where id=p_task;
    if t.id is null then raise exception 'المهمّةُ غيرُ موجودة'; end if;
    if t.kind <> 'notify_guardian' then
      raise exception 'هذي ليست مهمّةَ إشعارِ وليّ الأمر'; end if;
    rid := t.record_id;
  end if;

  select coalesce(max(attempt_no),0)+1 into n from v2.guardian_contacts
   where student_id=p_student and coalesce(task_id,'00000000-0000-0000-0000-000000000000'::uuid)
         = coalesce(p_task,'00000000-0000-0000-0000-000000000000'::uuid);

  insert into v2.guardian_contacts(school_id,student_id,guardian_id,task_id,record_id,
      channel,at_time,outcome,summary_ar,guardian_say,right_number,by_person,attempt_no,is_test)
  values (sc,p_student,gid,p_task,rid,p_channel,p_at,p_outcome,
      nullif(btrim(coalesce(p_summary,'')),''),
      nullif(btrim(coalesce(p_guardian_say,'')),''),
      nullif(btrim(coalesce(p_right_number,'')),''),
      v2.current_person(),n,
      coalesce((select test_mode from v2.schools where id=sc),false))
  returning id into nid;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (sc,'guardian_contact',current_date,p_student,
      'اتّصلت بك المدرسةُ — '||p_channel,
      p_outcome||coalesce(' · '||btrim(p_summary),''),
      'guardian_contacts',nid,'all',
      coalesce((select test_mode from v2.schools where id=sc),false));

  if p_task is not null and p_outcome in ('ردّ وعلم','ردّ ورفض') then
    update v2.behavior_tasks set status='done', done_at=now(),
        done_by=v2.current_person(), ev_on=coalesce(ev_on,current_date),
        ev_text='أُشعر وليُّ الأمر — '||p_channel||' · '||p_outcome||
                coalesce(' · '||btrim(p_summary),'')
     where id=p_task and status<>'done';
    closed := found;
  end if;

  return jsonb_build_object('ok',true,'contact',nid,'attempt',n,
    'attempt_ar',v2.ar_num(n),'closed',closed,
    'note', case when closed then 'أُثبت الإشعارُ وأُقفلت المهمّة'
                 when p_outcome in ('ردّ وعلم','ردّ ورفض') then 'أُثبت الإشعار'
                 else 'أُثبتت المحاولةُ — والمهمّةُ باقيةٌ حتى يُشعَر' end);
end $function$
;
