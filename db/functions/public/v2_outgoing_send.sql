-- public.v2_outgoing_send(p_mail uuid, p_channel text, p_ref text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9b76e8d932984a1960c78b6e596bfec7
CREATE OR REPLACE FUNCTION public.v2_outgoing_send(p_mail uuid, p_channel text, p_ref text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; closed jsonb := '[]'::jsonb; t record; n integer := 0; w integer := 0;
        msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'إخراج الصادر');
  select * into m from v2.outgoing_mail where id = p_mail;
  if m.id is null then raise exception 'الخطابُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'إخراج الصادر');
  if m.status <> 'signed' then
    raise exception 'لا يخرج إلّا ما وُقّع — ووقّعه المديرُ أوّلًا، فرقمُ الصادر لا يُعطى بغير توقيع';
  end if;
  if p_channel is null then raise exception 'قناةُ الإخراج لا تُترك فارغةً — ومنها يُعرف أين يُتابَع'; end if;
  if p_channel = 'نظام رسمي' and coalesce(btrim(p_ref),'') = '' then
    raise exception 'إن خرج في النظام الرسميّ فلا بدَّ من مرجع إحالته — وبه يُتابَع';
  end if;

  update v2.outgoing_mail set status='sent', sent_on=current_date,
      sent_channel=p_channel, sent_ref=nullif(btrim(p_ref),'')
   where id = p_mail;

  for t in select bt.* from v2.outgoing_links lt
            join v2.behavior_tasks bt on bt.id = lt.source_id and lt.source = 'behavior'
           where lt.mail_id = p_mail and lt.on_event = 'sent' and bt.status <> 'done' loop
    update v2.behavior_tasks set status='done', done_at=now(), done_by=v2.current_person(),
        ev_on=current_date, ev_ref='الصادر '||v2.ar_num(m.serial_no),
        auto_note='رُفع بالصادر رقم '||v2.ar_num(m.serial_no)||' إلى '||m.to_entity||
                  ' · '||p_channel||coalesce(' · مرجعُه '||nullif(btrim(p_ref),''),'')
     where id = t.id;
    closed := closed || jsonb_build_object('task',t.id,'text',t.text_ar);
    n := n + 1;
  end loop;

  n := n + v2.outgoing_absence_close(p_mail, 'sent',
        'رُفع بالصادر رقم '||v2.ar_num(m.serial_no)||' إلى '||m.to_entity||' · '||p_channel);

  select count(*) into w from v2.outgoing_links where mail_id = p_mail and on_event='replied';

  perform v2.log_action(m.school_id,null,'outgoing_send','خرج خطابٌ صادر',
    'outgoing_mail',p_mail, jsonb_build_object('serial',m.serial_no,'channel',p_channel,'closed',n));

  return v2.outgoing_card(p_mail) || jsonb_build_object('ok', true,
    'closed', closed,
    'note_ar','خرج الصادرُ رقم '||v2.ar_num(m.serial_no)||' إلى '||m.to_entity||
      case when n > 0 then ' · وأُقفل به '||
        v2.ar_count(n,'بندٌ واحد','بندان','بنود','بندًا') else '' end||
      case when w > 0 then ' · ويبقى '||
        v2.ar_count(w,'بندٌ واحدٌ ينتظر','بندان ينتظران','بنودٍ تنتظر','بندًا ينتظر')||
        ' جوابَ الجهة، فلا يُقفل بخروج الخطاب' else '' end);
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_outgoing_send','المراسلات','إخراج صادر',
    jsonb_build_object('mail',p_mail,'channel',p_channel),st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;
