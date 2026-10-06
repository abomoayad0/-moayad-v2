-- public.v2_committee_task_done(p_item uuid, p_note text, p_evidence text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e80ec9be900410b985a6775b96659064
CREATE OR REPLACE FUNCTION public.v2_committee_task_done(p_item uuid, p_note text, p_evidence text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare i record; m record; me uuid;
begin
  me := v2.current_person();
  select * into i from v2.meeting_items where id=p_item;
  if i.id is null then raise exception 'البندُ غيرُ موجود'; end if;
  select * into m from v2.committee_meetings where id=i.meeting_id;
  if not v2.my_school(m.school_id) then raise exception 'ليست مدرستك'; end if;
  if m.status <> 'معتمد' then raise exception 'لا يُنفَّذ قرارٌ من محضرٍ لم يُعتمد'; end if;
  if i.outcome <> 'أُقرّ' then raise exception 'هذا البندُ % — ولا تنفيذَ له', i.outcome; end if;
  if i.done_at is not null then raise exception 'أُقرّ تنفيذُه سلفًا'; end if;
  if i.owner_person is distinct from me
     and v2.my_seat(m.school_id,m.committee_key) is distinct from 'chair' then
    raise exception 'إقرارُ التنفيذ لمن أُسند إليه القرار أو لرئيس اللجنة'; end if;
  if btrim(coalesce(p_note,''))='' then
    raise exception 'اكتب ما فعلتَ — فلا يُقفل قرارٌ بلا بيان'; end if;

  update v2.meeting_items set done_at=now(), done_by=me,
      done_note=btrim(p_note),
      done_evidence=nullif(btrim(coalesce(p_evidence,'')),'')
   where id=p_item;

  if i.student_id is not null then
    insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
        ref_table,ref_id,visible_to,is_test)
    values (m.school_id,'committee',current_date,i.student_id,
        'نُفّذ قرارُ اللجنة','نُفّذ ما قرّرته اللجنةُ في شأنه',
        'meeting_items',p_item,'staff',
        coalesce((select test_mode from v2.schools where id=m.school_id),false));
  end if;
  return jsonb_build_object('ok',true);
end $function$
;
