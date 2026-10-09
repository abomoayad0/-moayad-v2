-- v2.outgoing_card(p_mail uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 98e8b99145dffcb1b30d1b31b683b15e
CREATE OR REPLACE FUNCTION v2.outgoing_card(p_mail uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select jsonb_build_object(
    'mail', m.id,
    'serial_ar', case when m.serial_no is null then 'بلا رقمٍ — لم يُوقَّع بعد'
                      else 'الصادر رقم '||v2.ar_num(m.serial_no) end,
    'serial', m.serial_no,
    'subject', m.subject_ar,
    'body', m.body_ar,
    'to_entity', m.to_entity,
    'kind', m.kind,
    'kind_ar', case m.kind when 'letter' then 'خطاب' when 'report' then 'تقريرٌ أو محضر'
                           when 'decision' then 'قرار' when 'referral' then 'إحالة'
                           when 'circular' then 'تعميم' else 'ردٌّ على وارد' end,
    'secrecy', m.secrecy,
    'status', m.status,
    'state_ar', v2.outgoing_state_ar(m.status, m.needs_reply, m.cancel_reason),
    'issued_ar', case when m.issued_on_g is null then null
                      else coalesce(m.issued_on_h, v2.fn_to_hijri(m.issued_on_g))||' هـ' end,
    'signed_by', (select full_name from v2.people where id = m.signed_by),
    'prepared_by', (select full_name from v2.people where id = m.prepared_by),
    'sent_on', m.sent_on,
    'sent_channel', m.sent_channel,
    'sent_ref', m.sent_ref,
    'needs_reply', m.needs_reply,
    'reply_due_on', m.reply_due_on,
    'reply_due_ar', case when m.reply_due_on is null then null
                         else v2.fn_to_hijri(m.reply_due_on)||' هـ' end,
    'overdue_ar', case when m.needs_reply and m.reply_on is null and m.reply_due_on is not null
                            and m.reply_due_on < current_date
                       then 'تأخّر الجوابُ '||v2.ar_count(current_date - m.reply_due_on,
                              'يومًا واحدًا','يومين','أيّام','يومًا')||' عن موعده'
                       else null end,
    'reply_on', m.reply_on,
    'reply_ref', m.reply_ref,
    'reply_note', m.reply_note,
    'close_note', m.close_note,
    'cancel_reason', m.cancel_reason,
    'reply_to', (select jsonb_build_object('mail', i.id, 'subject', i.subject_ar,
                          'from', i.from_entity, 'serial', i.serial_no)
                   from v2.incoming_mail i where i.id = m.reply_to_mail),
    'attachments', (select coalesce(jsonb_agg(jsonb_build_object(
                        'id',a.id,'kind',a.kind,'name',a.name_ar,
                        'url',a.url,'barcode',a.barcode_val,'form_entry',a.form_entry)
                      order by a.created_at),'[]'::jsonb)
                      from v2.outgoing_attachments a where a.mail_id = m.id),
    'tasks', (select coalesce(jsonb_agg(jsonb_build_object(
                  'task', t.id, 'kind', t.kind, 'text', t.text_ar,
                  'owner', t.owner_role, 'status', t.status,
                  'closes_on', lt.on_event,
                  'closes_on_ar', case lt.on_event
                     when 'sent' then 'يُقفل بخروج الخطاب'
                     else 'لا يُقفل إلّا بجواب الجهة' end,
                  'student', (select s.full_name from v2.behavior_records r
                               join v2.students s on s.id = r.student_id
                              where r.id = t.record_id))
                order by lt.on_event, t.ord),'[]'::jsonb)
                from v2.outgoing_links lt
                join v2.behavior_tasks t on t.id = lt.source_id and lt.source = 'behavior'
               where lt.mail_id = m.id),
    'absence_tasks', (select coalesce(jsonb_agg(jsonb_build_object(
                  'task', ab.id, 'kind', ab.kind, 'text', ab.text_ar,
                  'owner', ab.owner_role, 'status', ab.status,
                  'closes_on', lt.on_event,
                  'closes_on_ar', case lt.on_event
                     when 'sent' then 'يُقفل بخروج الخطاب'
                     else 'لا يُقفل إلّا بجواب الجهة' end,
                  'student', (select s2.full_name from v2.absence_cases c
                               join v2.students s2 on s2.id = c.student_id
                              where c.id = ab.case_id))
                order by lt.on_event, ab.ord),'[]'::jsonb)
                from v2.outgoing_links lt
                join v2.absence_tasks ab on ab.id = lt.source_id and lt.source = 'absence'
               where lt.mail_id = m.id)
  )
  from v2.outgoing_mail m where m.id = p_mail
$function$
;
