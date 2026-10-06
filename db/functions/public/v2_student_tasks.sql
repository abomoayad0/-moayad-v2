-- public.v2_student_tasks(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 69827df8e485ef0e0a4480042eb7262a
CREATE OR REPLACE FUNCTION public.v2_student_tasks(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_student(p_student,'مهامّ الطالب');
  select coalesce(jsonb_agg(jsonb_build_object(
      'task',t.id,'record',t.record_id,'ord',t.ord,
      'kind',t.kind,
      'kind_ar', case t.kind
        when 'notify_guardian' then 'إشعار وليّ الأمر'
        when 'follow_up' then 'حصر السلوكيّات والمتابعة'
        when 'summon_guardian' then 'دعوة وليّ الأمر'
        when 'record_sign' then 'التدوين والتوقيع'
        when 'counselor' then 'التحويل إلى الموجّه'
        when 'committee' then 'التحويل إلى اللجنة'
        when 'plan' then 'خطّة تعديل السلوك'
        when 'compensation' then 'فرص التعويض'
        when 'deduct' then 'الحسم'
        when 'repair' then 'إصلاح التالف'
        when 'seize' then 'المضبوطات'
        else 'إجراءٌ تربويّ' end,
      'text',t.text_ar,
      'owner_role',t.owner_role,
      'owner_role_ar', v2.owner_ar(t.owner_role),
      'origin',t.origin,
      'status',t.status,'skip_reason',t.skip_reason,
      'done_at',t.done_at,
      'done_by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=t.done_by),
      'owner_person',t.owner_person,
      'owner_ar',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=t.owner_person),
      'delegate_note',t.delegate_note,
      'evidence_kind',t.evidence_kind,
      'evidence_ar',(select k.label_ar from v2.evidence_kinds k where k.key=t.evidence_kind),
      'hint_ar',(select k.hint_ar from v2.evidence_kinds k where k.key=t.evidence_kind),
      'form_no', v2.task_form_no(t.kind),
      'form_title',(select f.title_ar from v2.official_forms f
                     where f.form_no = v2.task_form_no(t.kind)),
      'needs_date', (t.evidence_kind is not null),
      'needs_text', (t.evidence_kind is not null),
      'needs_file', t.evidence_kind in ('guardian_notice','meeting','repair','seizure'),
      'needs_ref',  t.evidence_kind in ('form','referral'),
      'needs_people', t.evidence_kind in ('meeting','committee'),
      'needs_signature', t.evidence_kind in ('record_sign','pledge','meeting'),
      'lbl_date','تاريخ التنفيذ','lbl_text','ما تمّ',
      'lbl_file','المرفق','lbl_ref','المرجع',
      'lbl_people','الحاضرون','lbl_sign','التوقيع',
      'ev_on',t.ev_on,'ev_text',t.ev_text,'ev_file',t.ev_file,
      'ev_ref',t.ev_ref,'ev_people',t.ev_people,'ev_signed',t.ev_signed,
      'problem',(select cp.text_ar from v2.behavior_records br
                  join v2.conduct_problems cp on cp.id=br.problem_id where br.id=t.record_id),
      'degree_ar',(select v2.degree_ar(cp.degree_no) from v2.behavior_records br
                  join v2.conduct_problems cp on cp.id=br.problem_id where br.id=t.record_id),
      'step',(select br.step_no from v2.behavior_records br where br.id=t.record_id),
      'step_ar',(select v2.ar_num(br.step_no) from v2.behavior_records br where br.id=t.record_id),
      'occurrence_ar',(select v2.ord_ar(br.occurrence_no) from v2.behavior_records br
                        where br.id=t.record_id))
      order by t.record_id, t.ord),'[]'::jsonb)
  into r from v2.behavior_tasks t
  join v2.behavior_records br on br.id=t.record_id
  where br.student_id=p_student and br.status<>'voided';
  return r;
end $function$
;
