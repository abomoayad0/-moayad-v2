-- public.v2_task_card(p_task uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6e24964f4a81bc7b4fd0f25e219a6758
CREATE OR REPLACE FUNCTION public.v2_task_card(p_task uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  t record; k record; fn smallint; sgn text; lbl_sign text;
  v_entry uuid; v_estatus text; v_efinal boolean;
begin
  select bt.*, br.student_id, br.school_id, br.step_no, br.occurrence_no,
         cp.text_ar problem_ar, cp.degree_no
    into t
    from v2.behavior_tasks bt
    join v2.behavior_records br on br.id = bt.record_id
    join v2.conduct_problems cp on cp.id = br.problem_id
   where bt.id = p_task;
  if t.id is null then raise exception 'المهمّةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(t.student_id,'بطاقةُ المهمّة');

  select * into k from v2.evidence_kinds where key = t.evidence_kind;
  fn := v2.form_for_kind(t.kind, t.school_id);

  select fe.id, fe.status, fe.finalized_at is not null
    into v_entry, v_estatus, v_efinal
    from v2.form_entries fe
   where fe.task_id = p_task and fn is not null and fe.form_no = fn and fe.status <> 'void'
   order by fe.created_at desc limit 1;

  sgn := case t.kind
           when 'record_sign'   then 'الطالب'
           when 'guardian_sign' then 'وليّ الأمر'
           when 'pledge'        then 'الطالب ووليُّ أمره'
           else null end;

  lbl_sign := case when sgn is null then k.lbl_sign
                   else 'وقّع '||sgn||' بالعلم' end;

  return jsonb_build_object(
    'task', jsonb_build_object(
      'id', t.id, 'kind', t.kind, 'text_ar', t.text_ar,
      'owner_role', t.owner_role, 'status', t.status, 'ord', t.ord,
      'origin', t.origin, 'skip_reason', t.skip_reason, 'auto_note', t.auto_note,
      'record', t.record_id, 'student', t.student_id,
      'step_ar', v2.ar_num(t.step_no), 'degree_ar', v2.degree_ar(t.degree_no),
      'occurrence_ar', v2.ord_ar(t.occurrence_no),
      'problem_ar', rtrim(btrim(t.problem_ar),'.')),
    'evidence', case when k.key is null then null else jsonb_build_object(
      'key', k.key, 'label_ar', k.label_ar, 'hint_ar', k.hint_ar,
      'needs', jsonb_build_object(
        'date', k.needs_date, 'text', k.needs_text, 'file', k.needs_file,
        'ref', k.needs_ref, 'people', k.needs_people,
        'signature', k.needs_signature, 'form', fn),
      'labels', jsonb_build_object(
        'date', k.lbl_date, 'text', k.lbl_text, 'file', k.lbl_file,
        'ref', k.lbl_ref, 'people', k.lbl_people, 'sign', lbl_sign)) end,
    'signer_ar', sgn,
    'refusal', case when coalesce(k.needs_signature,false) then jsonb_build_object(
        'allowed', true,
        'label_ar', case when sgn is null then 'امتنع عن التوقيع'
                         else 'امتنع '||sgn||' عن التوقيع' end,
        'note_ar', 'الامتناعُ عن التوقيع يُتمّ الخطوةَ بسببٍ مكتوب — فلا يُحتجَز ملفُّ الطالب على توقيعه',
        'needs_reason', true) end,
    'form', case when fn is null then null else jsonb_build_object(
      'form_no', fn,
      'title_ar', (select title_ar from v2.official_forms where form_no = fn),
      'source', (select source_doc||' · '||source_page from v2.official_forms where form_no = fn),
      'why_ar', (select why_ar from v2.task_kind_forms where kind = t.kind),
      'entry', case when v_entry is null then null else jsonb_build_object(
        'id', v_entry, 'status', v_estatus, 'finalized', v_efinal) end,
      'ready', coalesce(v_estatus,'') = 'final') end,
    'filled', jsonb_build_object(
      'ev_on', t.ev_on, 'ev_text', t.ev_text, 'ev_file', t.ev_file,
      'ev_ref', t.ev_ref, 'ev_people', t.ev_people,
      'ev_signed', t.ev_signed, 'ev_refused_reason', t.ev_refused_reason),
    'door', case
      when t.kind = 'notify_guardian' then 'بابُه إثباتُ الاتّصال بوليّ الأمر'
      when t.kind = 'plan'            then 'بابُه كتابةُ خطّة تعديل السلوك'
      when t.kind = 'committee'       then 'بابُه تحويلُ الطالب إلى اللجنة'
      when t.kind = 'follow_up'       then 'بابُه حصرُ السلوكيّات'
      when t.evidence_kind = 'auto'   then 'يقع آليًّا — لا يُثبَت باليد'
      else 'بابُ الإثبات' end);
end
$function$
;
