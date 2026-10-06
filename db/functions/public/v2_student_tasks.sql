-- public.v2_student_tasks(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bea875fd87f2820d677c0c8b4e081a42
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
        else t.kind end,
      'text',t.text_ar,'owner',t.owner_role,'origin',t.origin,
      'status',t.status,'skip_reason',t.skip_reason,
      'done_at',t.done_at,
      'done_by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=t.done_by),
      'evidence_note',t.evidence_note,
      'evidence_kind',t.evidence_kind,
      'problem',(select cp.text_ar from v2.behavior_records br
                  join v2.conduct_problems cp on cp.id=br.problem_id where br.id=t.record_id),
      'degree_ar',(select v2.degree_ar(cp.degree_no) from v2.behavior_records br
                  join v2.conduct_problems cp on cp.id=br.problem_id where br.id=t.record_id),
      'step',(select br.step_no from v2.behavior_records br where br.id=t.record_id),
      'step_ar',(select v2.ar_num(br.step_no) from v2.behavior_records br where br.id=t.record_id))
      order by t.record_id, t.ord),'[]'::jsonb)
  into r from v2.behavior_tasks t
  join v2.behavior_records br on br.id=t.record_id
  where br.student_id=p_student and br.status<>'voided';
  return r;
end $function$
;
