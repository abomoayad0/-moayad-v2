-- public.v2_task_evidence(p_task uuid, p_on date, p_text text, p_file text, p_ref text, p_people text, p_signed boolean, p_refuse text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ceca9be9f49acc0b5a40e0e055b0d0f5
CREATE OR REPLACE FUNCTION public.v2_task_evidence(p_task uuid, p_on date DEFAULT NULL::date, p_text text DEFAULT NULL::text, p_file text DEFAULT NULL::text, p_ref text DEFAULT NULL::text, p_people text DEFAULT NULL::text, p_signed boolean DEFAULT NULL::boolean, p_refuse text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  t record; k record; fn smallint; v_entry uuid; miss text[] := array[]::text[];
  v_on date; v_sign boolean; v_note text; v_refused boolean;
  st text; m text; d text; h text; c text;
begin
  perform v2.assert_role(array['deputy_students','deputy','principal','counselor',
      'admin_assistant','admin_assistant_students'],'إثباتَ تنفيذ المهمّة');

  select bt.*, br.student_id, br.school_id into t
    from v2.behavior_tasks bt join v2.behavior_records br on br.id = bt.record_id
   where bt.id = p_task;
  if t.id is null then raise exception 'المهمّةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(t.student_id,'إثبات تنفيذ المهمّة');

  if t.status = 'done' then raise exception 'أُقفلت هذي المهمّةُ سلفًا'; end if;
  if t.status = 'skipped' then
    raise exception 'هذي المهمّةُ متخطّاةٌ — %', coalesce(t.skip_reason,'بسببٍ مكتوب'); end if;

  if t.kind = 'notify_guardian' then
    raise exception 'إشعارُ وليّ الأمر يُثبَت من باب الاتّصال — فالإشعارُ فعلان: رسالةٌ تخرج واتّصال'; end if;
  if t.kind = 'plan' then
    raise exception 'خطّةُ تعديل السلوك تُكتب من بابها، ولا تُقفل بإثبات'; end if;
  if t.kind = 'committee' then
    raise exception 'تحويلُ الطالب إلى اللجنة من بابه، ولا يُقفل بإثبات'; end if;
  if t.kind = 'follow_up' and t.evidence_kind = 'followup' then
    raise exception 'الحصرُ يُثبَت من باب حصر السلوكيّات'; end if;
  if t.evidence_kind = 'auto' then
    raise exception 'هذي المهمّةُ تقع آليًّا — ولا تُثبَت باليد'; end if;

  select * into k from v2.evidence_kinds where key = t.evidence_kind;
  if k.key is null then
    raise exception 'نوعُ الإثبات «%» غيرُ معروفٍ في الجدول', coalesce(t.evidence_kind,'—'); end if;

  v_on   := coalesce(p_on, current_date);
  v_sign := p_signed;

  -- 🔒 حارسُ التوقيع على القاصر
  if coalesce(k.needs_signature,false) then
    if v_sign is null then
      raise exception 'وقّع، أو أثبت الامتناعَ بسببٍ مكتوب — ولا تُترك الخطوةُ معلّقة'; end if;
    if not v_sign and btrim(coalesce(p_refuse,'')) = '' then
      raise exception 'الامتناعُ عن التوقيع لا يقع بلا سببٍ مكتوب'; end if;
  end if;

  -- 🔑 الامتناعُ: لا صورةَ له — فالسببُ المكتوبُ شاهدُه
  v_refused := coalesce(k.needs_signature,false) and v_sign is not null and not v_sign;

  if coalesce(k.needs_text,false)   and btrim(coalesce(p_text,''))   = '' and not v_refused then
    miss := array_append(miss, coalesce(k.lbl_text,'النصّ')); end if;
  if coalesce(k.needs_file,false)   and btrim(coalesce(p_file,''))   = '' and not v_refused then
    miss := array_append(miss, coalesce(k.lbl_file,'المرفق')); end if;
  if coalesce(k.needs_ref,false)    and btrim(coalesce(p_ref,''))    = '' then
    miss := array_append(miss, coalesce(k.lbl_ref,'الرقم المرجعيّ')); end if;
  if coalesce(k.needs_people,false) and btrim(coalesce(p_people,'')) = '' and not v_refused then
    miss := array_append(miss, coalesce(k.lbl_people,'من حضر')); end if;

  if array_length(miss,1) is not null then
    raise exception 'لا تُقفل المهمّةُ بلا: %', array_to_string(miss,' · '); end if;

  fn := v2.form_for_kind(t.kind, t.school_id);
  if fn is not null and not v_refused then
    select fe.id into v_entry from v2.form_entries fe
     where fe.task_id = p_task and fe.form_no = fn and fe.status = 'final'
     order by fe.created_at desc limit 1;
    if v_entry is null then
      raise exception 'لا تُقفل هذي المهمّةُ قبل اعتماد «%» (نموذج %) — افتحه من بطاقة المهمّة',
        (select title_ar from v2.official_forms where form_no = fn),
        translate(fn::text,'0123456789','٠١٢٣٤٥٦٧٨٩');
    end if;
    perform v2.fn_form_deliver(v_entry);
  end if;

  v_note := case when v_refused then 'امتنع عن التوقيع — '||btrim(p_refuse)
                 else nullif(btrim(coalesce(p_text,'')),'') end;

  update v2.behavior_tasks set
      status  = 'done', done_at = now(), done_by = v2.current_person(),
      ev_on   = v_on,
      ev_text = coalesce(v_note, ev_text),
      ev_file = coalesce(nullif(btrim(coalesce(p_file,'')),''), ev_file),
      ev_ref  = coalesce(nullif(btrim(coalesce(p_ref,'')),''), v_entry::text, ev_ref),
      ev_people = coalesce(nullif(btrim(coalesce(p_people,'')),''), ev_people),
      ev_signed = v_sign,
      ev_refused_reason = case when v_refused then btrim(p_refuse) end
   where id = p_task;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (t.school_id,'other',v_on,t.student_id,
      case when v_refused then 'امتناعٌ عن التوقيع — '||coalesce(k.label_ar,t.kind)
           else 'أُثبت تنفيذُ إجراء — '||coalesce(k.label_ar,t.kind) end,
      t.text_ar||coalesce(' · '||v_note,''),
      'behavior_tasks',p_task,'all',
      coalesce((select test_mode from v2.schools where id=t.school_id),false));

  perform v2.log_action(t.school_id,t.student_id,'task_evidence',
    case when v_refused then 'أُثبت امتناعٌ عن التوقيع' else 'أُثبت تنفيذُ إجراء' end,
    'behavior_tasks',p_task,
    jsonb_build_object('kind',t.kind,'evidence',t.evidence_kind,'signed',v_sign));

  return jsonb_build_object('ok',true,'task',p_task,'closed',true,
    'evidence_ar', k.label_ar, 'signed', v_sign, 'refused', v_refused, 'form', fn,
    'note', case
      when v_refused then 'أُثبت الامتناعُ عن التوقيع بسببه — وتمّت الخطوة · والسببُ المكتوبُ شاهدُها'
      when fn is not null then 'أُثبت التنفيذُ ومعه النموذجُ المعتمد — وأُقفلت المهمّة'
      else 'أُثبت التنفيذُ وأُقفلت المهمّة' end);
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_task_evidence','السلوك','إثبات تنفيذ المهمّة',
    jsonb_build_object('task',p_task,'signed',p_signed),
    st,d,h,c,'bridge', case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end
$function$
;
