-- public.v2_mail_card(p_mail uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0238aae3e8a56aa159e1510da9103d1c
CREATE OR REPLACE FUNCTION public.v2_mail_card(p_mail uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v_sec text; v_me uuid;
begin
  select school_id, secrecy into sc, v_sec from v2.incoming_mail where id=p_mail;
  if sc is null then raise exception 'الواردُ غيرُ موجود'; end if;
  perform v2.assert_my_school(sc,'قراءة بطاقة الوارد');
  if v_sec <> 'عادي' and not v2.may_read_secret_mail() then
    raise exception 'هذا واردٌ % — ولا يُقرأ إلّا من مدير المدرسة أو وكيلها · '
      'والسرّيّةُ من أحكام المواظبة والسلوك العامّة (م35 بند 5)', v_sec;
  end if;
  v_me := v2.current_person();
  return (select jsonb_build_object(
    'ok', true,
    'mail', jsonb_build_object('id',m.id,'serial_no',m.serial_no,'ref_no',m.ref_no,
      'subject',m.subject_ar,'from',m.from_entity,'body',m.body_ar,
      'received_h', m.received_on_h||' هـ', 'doc_date_h', m.doc_date_h,
      'secrecy', m.secrecy, 'status', m.status, 'source', m.source),
    'attachments', coalesce((select jsonb_agg(jsonb_build_object('name',a.file_name,'path',a.storage_path))
       from v2.mail_attachments a where a.mail_id=m.id),'[]'::jsonb),
    'items', coalesce((select jsonb_agg(jsonb_build_object(
        'id', i.id, 'ord', i.ord, 'text', i.text_ar, 'kind', i.kind, 'approved', i.approved,
        'starts_h', case when i.starts_on is null then null else v2.fn_to_hijri(i.starts_on)||' هـ' end,
        'ends_h', case when i.ends_on is null then null else v2.fn_to_hijri(i.ends_on)||' هـ' end,
        'targets', (select jsonb_agg(jsonb_build_object('role', t.role_ar,
            'person', (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=t.person_id),
            'assignment', t.assignment_ar, 'scope', t.scope_note))
          from v2.mail_targets t where t.item_id=i.id),
        'followups', (select jsonb_agg(jsonb_build_object(
            'id', f.id, 'role', f.role_ar, 'status', f.status,
            'mine', (f.person_id is not null and f.person_id = v_me),
            'person', (select v2.fn_display_name(pe2.full_name) from v2.people pe2 where pe2.id=f.person_id),
            'due_h', case when f.due_on is null then null else v2.fn_to_hijri(f.due_on)||' هـ' end,
            'late', (f.due_on is not null and f.due_on < current_date and f.status<>'done'),
            'done_h', case when f.done_at is null then null else v2.fn_to_hijri(f.done_at::date)||' هـ' end,
            'note', f.close_note, 'evidence', f.evidence_ref))
          from v2.mail_followups f where f.item_id=i.id))
        order by i.ord) from v2.mail_items i where i.mail_id=m.id),'[]'::jsonb),
    'my_followups_n', (select count(*) from v2.mail_items i
        join v2.mail_followups f on f.item_id=i.id
       where i.mail_id=m.id and f.person_id = v_me and f.status<>'done'),
    'acks', coalesce((select jsonb_agg(jsonb_build_object(
        'person', (select v2.fn_display_name(pe3.full_name) from v2.people pe3 where pe3.id=ak.person_id),
        'seen_h', case when ak.seen_at is null then null else v2.fn_to_hijri(ak.seen_at::date)||' هـ' end,
        'signed', ak.signed, 'refused', ak.refused, 'reason', ak.refuse_reason,
        'attachment', ak.sign_kind))
      from v2.mail_acknowledgements ak where ak.mail_id=m.id),'[]'::jsonb),
    'note_ar', 'ولكلّ موجَّهٍ إليه متابعتُه — وما وُسم «لك» هو متابعتُك أنت')
   from v2.incoming_mail m where m.id=p_mail);
end $function$
;
