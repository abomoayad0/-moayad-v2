-- public.v2_outgoing_pending(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 60f49eead06aecd0ac5de0188ba91f01
CREATE OR REPLACE FUNCTION public.v2_outgoing_pending(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v_draft jsonb; v_signed jsonb; v_await jsonb; v_tasks jsonb;
        n1 integer; n2 integer; n3 integer; n4 integer;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'ما ينتظر الصادر');
  sc := coalesce(p_school, v2.acting_school());
  perform v2.assert_my_school(sc,'ما ينتظر الصادر');

  select coalesce(jsonb_agg(jsonb_build_object('mail',m.id,'subject',m.subject_ar,
           'to_entity',m.to_entity,'age_days',current_date - m.created_at::date)
         order by m.created_at), '[]'::jsonb) into v_draft
    from v2.outgoing_mail m where m.school_id = sc and m.status = 'draft';

  select coalesce(jsonb_agg(jsonb_build_object('mail',m.id,'serial',m.serial_no,
           'subject',m.subject_ar,'to_entity',m.to_entity,
           'signed_ar',coalesce(m.issued_on_h, v2.fn_to_hijri(m.issued_on_g))||' هـ',
           'age_days',current_date - m.signed_at::date)
         order by m.serial_no), '[]'::jsonb) into v_signed
    from v2.outgoing_mail m where m.school_id = sc and m.status = 'signed';

  select coalesce(jsonb_agg(jsonb_build_object('mail',m.id,'serial',m.serial_no,
           'subject',m.subject_ar,'to_entity',m.to_entity,'sent_on',m.sent_on,
           'due_on',m.reply_due_on,
           'late_days', case when m.reply_due_on < current_date
                             then current_date - m.reply_due_on else 0 end)
         order by m.reply_due_on), '[]'::jsonb) into v_await
    from v2.outgoing_mail m
   where m.school_id = sc and m.status = 'sent' and m.needs_reply and m.reply_on is null;

  select coalesce(jsonb_agg(jsonb_build_object(
           'task', bt.id, 'kind', bt.kind, 'text', bt.text_ar, 'owner', bt.owner_role,
           'record', bt.record_id,
           'student', s.full_name,
           'need_ar', case when bt.kind = 'edu_decision'
                           then 'يُحمل على خطابٍ صادرٍ ولا يُقفل إلّا بجواب إدارة التعليم'
                           else 'ترفعه المدرسةُ بخطابٍ صادرٍ ويُقفل بخروجه' end)
         order by bt.kind, r.created_at), '[]'::jsonb) into v_tasks
    from v2.behavior_tasks bt
    join v2.behavior_records r on r.id = bt.record_id
    join v2.students s on s.id = r.student_id
   where r.school_id = sc
     and bt.kind in ('edu_report','edu_decision')
     and bt.status not in ('done','skipped')
     and r.status <> 'voided'
     and not exists (select 1 from v2.outgoing_mail_tasks lt
                      join v2.outgoing_mail om on om.id = lt.mail_id
                     where lt.task_id = bt.id and om.status <> 'cancelled');

  n1 := jsonb_array_length(v_draft);
  n2 := jsonb_array_length(v_signed);
  n3 := jsonb_array_length(v_await);
  n4 := jsonb_array_length(v_tasks);

  return jsonb_build_object(
    'drafts', v_draft,
    'signed_not_sent', v_signed,
    'awaiting_reply', v_await,
    'tasks_without_letter', v_tasks,
    'counts', jsonb_build_object('drafts',n1,'signed',n2,'awaiting',n3,'tasks',n4),
    'summary_ar',
      case when n1+n2+n3+n4 = 0 then 'لا شيءَ ينتظر الصادرَ الآن'
      else btrim(concat_ws(' · ',
        case when n4 > 0 then v2.ar_count(n4,'بندٌ واحدٌ من السلّم ينتظر خطابًا',
               'بندان من السلّم ينتظران خطابًا','بنودٍ من السلّم تنتظر خطابًا',
               'بندًا من السلّم ينتظر خطابًا') end,
        case when n1 > 0 then v2.ar_count(n1,'مسوّدةٌ واحدةٌ تنتظر توقيعَ المدير',
               'مسوّدتان تنتظران توقيعَ المدير','مسوّداتٍ تنتظر توقيعَ المدير',
               'مسوّدةً تنتظر توقيعَ المدير') end,
        case when n2 > 0 then v2.ar_count(n2,'خطابٌ مُوقَّعٌ لم يخرج',
               'خطابان مُوقَّعان لم يخرجا','خطاباتٍ مُوقَّعةٍ لم تخرج','خطابًا مُوقَّعًا لم يخرج') end,
        case when n3 > 0 then v2.ar_count(n3,'خطابٌ خرج وينتظر جوابًا',
               'خطابان خرجا وينتظران جوابًا','خطاباتٍ خرجت وتنتظر جوابًا',
               'خطابًا خرج وينتظر جوابًا') end)) end,
    'note_ar', 'وبنودُ السلّم المعروضةُ هنا هي التي أوجب الدليلُ رفعَها أو انتظارَ قرارٍ عليها — '||
               'وتُحمل على خطابٍ واحدٍ أو على خطاباتٍ، ولا تُقفل بيدٍ بل بخروج الخطاب أو بجواب الجهة');
end $function$
;
