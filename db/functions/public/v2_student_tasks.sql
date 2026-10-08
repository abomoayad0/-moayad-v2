-- public.v2_student_tasks(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d407ddd65a69eda8eda4e42a9f0cbc9d
CREATE OR REPLACE FUNCTION public.v2_student_tasks(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_student(p_student,'مهامّ الطالب');
  select coalesce(jsonb_agg(
      -- ① هُويّةُ المهمّة ونصُّها وصاحبُها
      jsonb_build_object(
        'task',t.id,'record',t.record_id,'ord',t.ord,
        'kind',t.kind,
        'kind_ar', case t.kind
          when 'notify_guardian' then 'إشعار وليّ الأمر'
          when 'follow_up' then 'حصر السلوكيّات والمتابعة'
          when 'summon_guardian' then 'دعوة وليّ الأمر'
          when 'record_sign' then 'التدوين والتوقيع'
          when 'guardian_sign' then 'توقيع وليّ الأمر'
          when 'counselor' then 'التحويل إلى الموجّه'
          when 'committee' then 'التحويل إلى اللجنة'
          when 'plan' then 'خطّة تعديل السلوك'
          when 'compensation' then 'فرص التعويض'
          when 'deduct' then 'الحسم'
          when 'repair' then 'إصلاح التالف'
          when 'seize' then 'المضبوطات'
          when 'pledge' then 'التعهّد'
          when 'program' then 'البرنامج التربويّ'
          when 'apology' then 'الاعتذار'
          when 'move_class' then 'نقل الفصل'
          when 'warn_move' then 'إنذارٌ بالنقل'
          else 'إجراءٌ تربويّ' end,
        'text',t.text_ar,
        'owner_role',t.owner_role,
        'owner_role_ar', v2.owner_ar(t.owner_role),
        'origin',t.origin,
        'status',t.status,'skip_reason',t.skip_reason,'auto_note',t.auto_note,
        'done_at',t.done_at,
        'done_by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=t.done_by),
        'owner_person',t.owner_person,
        'owner_ar',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=t.owner_person),
        'delegate_note',t.delegate_note)
      ||
      -- ② ما يطلبه نوعُ الإثبات — من جدوله لا من الكود
      jsonb_build_object(
        'evidence_kind',t.evidence_kind,
        'evidence_ar',  k.label_ar,
        'hint_ar',      k.hint_ar,
        'needs_date',      coalesce(k.needs_date,false),
        'needs_text',      coalesce(k.needs_text,false),
        'needs_file',      coalesce(k.needs_file,false),
        'needs_ref',       coalesce(k.needs_ref,false),
        'needs_people',    coalesce(k.needs_people,false),
        'needs_signature', coalesce(k.needs_signature,false),
        'lbl_date',   k.lbl_date, 'lbl_text',  k.lbl_text,
        'lbl_file',   k.lbl_file, 'lbl_ref',   k.lbl_ref,
        'lbl_people', k.lbl_people,
        'lbl_sign',   case when sg.v is null then k.lbl_sign else 'وقّع '||sg.v||' بالعلم' end,
        'signer_ar',  sg.v,
        'refusal_allowed', coalesce(k.needs_signature,false),
        'refusal_note_ar', case when coalesce(k.needs_signature,false)
          then 'الامتناعُ عن التوقيع يُتمّ الخطوةَ بسببٍ مكتوب — ولا يلزمه مرفق' end)
      ||
      -- ③ النموذجُ من الخريطة الواحدة · وحالُ قيده
      jsonb_build_object(
        'form_no',    fm.form_no,
        'form_title', (select f.title_ar from v2.official_forms f where f.form_no = fm.form_no),
        'form_secret',(select f.is_secret from v2.official_forms f where f.form_no = fm.form_no),
        'form_goes_to_ar',(select array_to_string(f.goes_to_ar,' · ') from v2.official_forms f
                            where f.form_no = fm.form_no),
        'form_entry', fe.id,
        'form_status', fe.status,
        'form_ready', coalesce(fe.status,'') = 'final')
      ||
      -- ④ ما أُثبت فعلًا · والبابُ · وموضعُ المهمّة من السلّم
      jsonb_build_object(
        'ev_on',t.ev_on,'ev_text',t.ev_text,'ev_file',t.ev_file,
        'ev_ref',t.ev_ref,'ev_people',t.ev_people,'ev_signed',t.ev_signed,
        'ev_refused_reason',t.ev_refused_reason,
        'door_ar', case
          when t.kind = 'notify_guardian' then 'إثباتُ الاتّصال بوليّ الأمر'
          when t.kind = 'plan'            then 'كتابةُ خطّة تعديل السلوك'
          when t.kind = 'committee'       then 'تحويلُ الطالب إلى اللجنة'
          when t.kind = 'follow_up' and t.evidence_kind='followup' then 'حصرُ السلوكيّات'
          when t.evidence_kind = 'services_review' then 'حالٌ مستمرّةٌ — لا تُؤشَّر'
          when t.evidence_kind = 'auto'   then 'يقع آليًّا'
          else 'بابُ الإثبات' end,
        'problem', cp.text_ar,
        'degree_ar', v2.degree_ar(cp.degree_no),
        'step', br.step_no,
        'step_ar', v2.ar_num(br.step_no),
        'occurrence_ar', v2.ord_ar(br.occurrence_no))
      order by t.record_id, t.ord),'[]'::jsonb)
  into r
  from v2.behavior_tasks t
  join v2.behavior_records br on br.id = t.record_id
  join v2.conduct_problems cp on cp.id = br.problem_id
  left join v2.evidence_kinds k on k.key = t.evidence_kind
  left join lateral (select v2.form_for_kind(t.kind, br.school_id) form_no) fm on true
  left join lateral (select case t.kind
        when 'record_sign'   then 'الطالب'
        when 'guardian_sign' then 'وليّ الأمر'
        when 'pledge'        then 'الطالب ووليُّ أمره'
      end v) sg on true
  left join lateral (
      select fe2.id, fe2.status from v2.form_entries fe2
       where fe2.task_id = t.id and fm.form_no is not null
         and fe2.form_no = fm.form_no and fe2.status <> 'void'
       order by fe2.created_at desc limit 1) fe on true
  where br.student_id = p_student and br.status <> 'voided';
  return r;
end
$function$
;
