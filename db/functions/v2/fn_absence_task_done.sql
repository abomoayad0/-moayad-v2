-- v2.fn_absence_task_done(p_task uuid, p_ev jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 eac87fdff2090cfe86ba65c42711f9b2
CREATE OR REPLACE FUNCTION v2.fn_absence_task_done(p_task uuid, p_ev jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t record; k v2.evidence_kinds; st uuid; miss text[];
begin
  select * into t from v2.absence_tasks where id=p_task;
  if t.id is null then raise exception 'المهمة غير موجودة'; end if;
  select c.student_id into st from v2.absence_cases c where c.id=t.case_id;
  perform v2.assert_my_student(st,'إغلاق مهمّة غياب');
  if t.owner_person is not null then
    if t.owner_person <> v2.current_person()
       and v2.my_role() not in ('deputy_students','deputy','principal') then
      raise exception 'هذه المهمّة مُسندة إلى %، فلا تُغلق إلا منه أو من الوكيل',
        (select v2.fn_display_name(full_name) from v2.people where id=t.owner_person); end if;
  else
    perform v2.assert_role(array['counselor','deputy_students','admin_assistant','principal'],
      'إغلاق مهامّ الغياب');
  end if;
  if t.status <> 'open' then raise exception 'هذه المهمة ليست مفتوحة — حالتها: %', t.status; end if;
  select * into k from v2.evidence_kinds where key = coalesce(t.evidence_kind,'note');
  miss := v2.fn_missing(k, p_ev);
  if array_length(miss,1) is not null then
    raise exception 'لا تُغلق «%» بلا إثبات. ينقص: % — (%)',
      t.text_ar, array_to_string(miss,' · '), k.hint_ar; end if;
  update v2.absence_tasks set status='done', done_at=now(), done_by=v2.current_person(),
    ev_on=(p_ev->>'on')::date, ev_text=p_ev->>'text', ev_file=p_ev->>'file',
    ev_ref=p_ev->>'ref', ev_people=p_ev->>'people',
    ev_signed=(p_ev->>'signed')::boolean, ev_refused_reason=p_ev->>'refused_reason'
   where id=p_task;
  return jsonb_build_object('closed',true,'evidence_kind',k.key,'evidence_ar',k.label_ar);
end $function$
;
