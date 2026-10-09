-- public.v2_contact_log(p_student uuid, p_task uuid, p_channel text, p_outcome text, p_summary text, p_guardian_say text, p_at time without time zone, p_right_number text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6ee7330254ce47683395eb83d9c1462f
CREATE OR REPLACE FUNCTION public.v2_contact_log(p_student uuid, p_task uuid, p_channel text, p_outcome text, p_summary text, p_guardian_say text, p_at time without time zone, p_right_number text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare sc uuid; gid uuid; rid uuid; n smallint; nid uuid; t record; ab record;
        closed boolean := false; v_issue jsonb; v_answered boolean; v_note text; v_form smallint;
        v_src text := 'none'; v_kind text;
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

  -- ══ البندُ يُعرف جنسُه: سلوكٌ أم مواظبة ══
  if p_task is not null then
    select * into t from v2.behavior_tasks where id = p_task;
    if t.id is not null then
      v_src := 'behavior'; v_kind := t.kind; rid := t.record_id;
      if t.kind <> 'notify_guardian' then
        raise exception 'هذي ليست مهمّةَ إشعارِ وليّ الأمر'; end if;
    else
      select x.id, x.kind, x.status, x.case_id into ab
        from v2.absence_tasks x where x.id = p_task;
      if ab.id is null then raise exception 'المهمّةُ غيرُ موجودة'; end if;
      v_src := 'absence'; v_kind := ab.kind;
      if ab.kind not in ('notify_guardian','warn_guardian','summon_guardian') then
        raise exception '%', 'بندُ المواظبة هذا ليس من بنود مخاطبة وليّ الأمر — '||
          'وبنودُها: الإبلاغُ والتنبيهُ والاستدعاء'; end if;
    end if;
  end if;

  select coalesce(max(attempt_no),0)+1 into n from v2.guardian_contacts
   where student_id=p_student
     and coalesce(source_id,'00000000-0000-0000-0000-000000000000'::uuid)
         = coalesce(p_task,'00000000-0000-0000-0000-000000000000'::uuid);

  insert into v2.guardian_contacts(school_id,student_id,guardian_id,task_id,record_id,
      source,source_id,channel,at_time,outcome,summary_ar,guardian_say,right_number,
      by_person,attempt_no,is_test)
  values (sc,p_student,gid,
      case when v_src='behavior' then p_task end, rid,
      v_src, p_task, p_channel,p_at,p_outcome,
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

  v_answered := p_outcome in ('ردّ وعلم','ردّ ورفض');

  -- ══ إقفالُ بندِ السلوك: بخروج الإشعار المكتوب ══
  if v_src = 'behavior' and rid is not null then
    v_form := v2.form_for_kind('notify_guardian', sc);

    if v_form is null then
      update v2.behavior_tasks
         set auto_note='لم يخرج الإشعارُ المكتوب — لم يُضبط نموذجُ الإشعار في لوحة التحكّم'
       where id=p_task;
    else
      v_issue := v2.fn_form_issue(
        v_form, p_student, rid, p_task,
        jsonb_build_object('on_date', current_date),
        v2.current_person());

      if (v_issue->>'ok')::boolean then
        v_note := case when v_answered
          then 'أُشعر وليُّ الأمر — '||p_channel||' · '||p_outcome||
               coalesce(' · '||btrim(p_summary),'')||
               ' · وخرج الإشعارُ المكتوب ('||
               (select title_ar from v2.official_forms where form_no=v_form)||
               ') وسُلّم إلى بوّابته'
          else 'تعذّر الاتصال ('||p_outcome||') — فخرج الإشعارُ المكتوب بديلًا '||
               'وسُلّم إلى بوّابته · وأُشّر بتعذّر الاتصال' end;
        update v2.behavior_tasks set status='done', done_at=now(),
            done_by=v2.current_person(), ev_on=coalesce(ev_on,current_date),
            ev_text=v_note, ev_ref=(v_issue->>'entry')
         where id=p_task and status<>'done';
        closed := found;
      else
        update v2.behavior_tasks
           set ev_ref=(v_issue->>'entry'),
               auto_note='لم يخرج الإشعارُ المكتوب بعد — '||coalesce(v_issue->>'why','')||
                         ' · والمهمّةُ باقيةٌ حتى يخرج ويُسلَّم'
         where id=p_task;
      end if;
    end if;

  -- ══ وبندُ المواظبة: الإبلاغُ والتنبيهُ يُقفلان بالاتّصال · والاستدعاءُ لا يُقفل إلّا بالاجتماع ══
  elsif v_src = 'absence' then
    if ab.status <> 'done' then
      if v_kind in ('notify_guardian','warn_guardian') and v_answered then
        update v2.absence_tasks set status='done', done_at=now(), done_by=v2.current_person(),
            ev_on=current_date, ev_ref='اتّصالٌ رقم '||v2.ar_num(n),
            ev_text='أُبلغ وليُّ الأمر — '||p_channel||' · '||p_outcome||
                    coalesce(' · '||btrim(p_summary),'')
         where id=p_task and status<>'done';
        closed := found;
      elsif v_kind in ('notify_guardian','warn_guardian') then
        update v2.absence_tasks set ev_on=coalesce(ev_on,current_date),
            ev_text='تعذّر الاتصال ('||p_outcome||') — والمحاولةُ مُثبتةٌ برقمها، '||
                    'والبندُ باقٍ حتى يُبلَّغ أو يخرج له ورقٌ بديل'
         where id=p_task;
      else
        update v2.absence_tasks set ev_on=coalesce(ev_on,current_date),
            ev_text='أُثبت الاتّصالُ بالدعوة — '||p_channel||' · '||p_outcome||
                    ' · وتمامُ البند بالاجتماع الحضوريّ لا بالاتّصال'
         where id=p_task;
      end if;
    end if;
  end if;

  perform v2.log_action(sc,p_student,'contact_log','أُثبت اتّصالٌ بوليّ الأمر',
    'guardian_contacts',nid, jsonb_build_object('channel',p_channel,'outcome',p_outcome,
      'source',v_src));
  return jsonb_build_object('ok',true,'contact',nid,'attempt',n,
    'attempt_ar',v2.ar_num(n),'closed',closed,
    'source',v_src,
    'source_ar', case v_src when 'behavior' then 'بندُ سلوك'
                            when 'absence'  then 'بندُ مواظبة'
                            else 'بلا بندٍ يحمله' end,
    'notice', v_issue,
    'note', case
      when closed and v_src='absence' and v_answered
        then 'أُثبت الاتصالُ وأُبلغ وليُّ الأمر — وأُقفل بندُ المواظبة بشاهده'
      when closed and p_outcome in ('ردّ وعلم','ردّ ورفض')
        then 'أُثبت الاتصالُ وخرج الإشعارُ المكتوب وسُلّم — وأُقفلت المهمّة'
      when closed
        then 'تعذّر الاتصالُ وخرج الإشعارُ المكتوب بديلًا وسُلّم — وأُقفلت المهمّة وأُشّر بالتعذّر'
      when v_src='absence' and v_kind='summon_guardian'
        then 'أُثبت الاتصالُ بالدعوة — والبندُ باقٍ حتى يُعقد الاجتماعُ الحضوريّ'
      when v_issue is not null
        then 'أُثبتت المحاولةُ — ولم يخرج الإشعارُ المكتوب: '||coalesce(v_issue->>'why','')
      else 'أُثبتت المحاولة' end);
end $function$
;
