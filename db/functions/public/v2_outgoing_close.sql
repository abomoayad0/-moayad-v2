-- public.v2_outgoing_close(p_mail uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4a84b2bb4720e5a050f2956b3fcd290d
CREATE OR REPLACE FUNCTION public.v2_outgoing_close(p_mail uuid, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; v_open integer;
        msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'إقفال الصادر');
  select * into m from v2.outgoing_mail where id = p_mail;
  if m.id is null then raise exception 'الخطابُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'إقفال الصادر');
  if m.status not in ('sent','replied') then
    raise exception 'لا يُقفل إلّا ما خرج — وحالُه: %',
      v2.outgoing_state_ar(m.status, m.needs_reply, m.cancel_reason);
  end if;
  if m.needs_reply and m.reply_on is null then
    raise exception 'هذا الخطابُ ينتظر جوابَ الجهة ولم يُسجَّل جوابُه — '
      'فسجّل الجوابَ أوّلًا، أو ارفع انتظارَ الجواب عنه بقرارٍ مكتوب';
  end if;

  select count(*) into v_open from v2.outgoing_links lt
    join v2.behavior_tasks bt on bt.id = lt.source_id and lt.source = 'behavior'
   where lt.mail_id = p_mail and bt.status <> 'done';
  v_open := v_open + v2.outgoing_absence_open(p_mail);
  if v_open > 0 then
    raise exception 'لا يُقفل وفيه % لم تُقفل — فأقفلها أو احملها على خطابٍ آخر',
      v2.ar_count(v_open,'بندٌ واحد','بندان','بنود','بندًا');
  end if;

  update v2.outgoing_mail set status='closed', closed_at=now(),
      close_note = nullif(btrim(p_note),'') where id = p_mail;

  perform v2.log_action(m.school_id,null,'outgoing_close','أُقفل خطابٌ صادر',
    'outgoing_mail',p_mail,'{}'::jsonb);

  return v2.outgoing_card(p_mail) || jsonb_build_object('ok', true,
    'note_ar','أُقفل الصادرُ رقم '||v2.ar_num(m.serial_no)||' — ويبقى في السجلّ لا يُحذف');
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_outgoing_close','المراسلات','إقفال صادر',
    jsonb_build_object('mail',p_mail),st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;
