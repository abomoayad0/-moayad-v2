-- public.v2_outgoing_reply(p_mail uuid, p_on date, p_ref text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5dd353ff142efb4d55e7f2570d55c4f3
CREATE OR REPLACE FUNCTION public.v2_outgoing_reply(p_mail uuid, p_on date DEFAULT NULL::date, p_ref text DEFAULT NULL::text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; t record; n integer := 0; closed jsonb := '[]'::jsonb;
        msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'تسجيل جواب الجهة');
  select * into m from v2.outgoing_mail where id = p_mail;
  if m.id is null then raise exception 'الخطابُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'تسجيل جواب الجهة');
  if m.status not in ('sent','replied') then
    raise exception 'لا يُسجَّل جوابٌ على خطابٍ لم يخرج — وحالُه: %', m.status;
  end if;
  if coalesce(btrim(p_note),'') = '' and coalesce(btrim(p_ref),'') = '' then
    raise exception 'الجوابُ يلزمه مرجعُه أو خلاصتُه مكتوبةً — فلا يُسجَّل جوابٌ بلا بيان';
  end if;

  update v2.outgoing_mail set status='replied',
      reply_on = coalesce(p_on, current_date),
      reply_ref = nullif(btrim(p_ref),''),
      reply_note = nullif(btrim(p_note),'')
   where id = p_mail;

  for t in select bt.* from v2.outgoing_mail_tasks lt
            join v2.behavior_tasks bt on bt.id = lt.task_id
           where lt.mail_id = p_mail and lt.on_event = 'replied' and bt.status <> 'done' loop
    update v2.behavior_tasks set status='done', done_at=now(), done_by=v2.current_person(),
        ev_on = coalesce(p_on, current_date),
        ev_ref = coalesce(nullif(btrim(p_ref),''),'جوابُ الصادر '||v2.ar_num(m.serial_no)),
        auto_note = 'وصل جوابُ '||m.to_entity||' على الصادر رقم '||v2.ar_num(m.serial_no)||
                    coalesce(' · مرجعُه '||nullif(btrim(p_ref),''),'')||
                    coalesce(' · '||nullif(btrim(p_note),''),'')
     where id = t.id;
    closed := closed || jsonb_build_object('task',t.id,'text',t.text_ar);
    n := n + 1;
  end loop;

  perform v2.log_action(m.school_id,null,'outgoing_reply','وصل جوابُ جهةٍ على صادر',
    'outgoing_mail',p_mail, jsonb_build_object('serial',m.serial_no,'closed',n));

  return v2.outgoing_card(p_mail) || jsonb_build_object('ok', true, 'closed', closed,
    'note_ar','سُجّل جوابُ '||m.to_entity||' على الصادر رقم '||v2.ar_num(m.serial_no)||
      case when n > 0 then ' · وأُقفل به '||
        v2.ar_count(n,'بندٌ واحدٌ كان ينتظره','بندان كانا ينتظرانه','بنودٍ كانت تنتظره','بندًا كان ينتظره')
      else ' · ولا بندَ كان ينتظره' end);
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_outgoing_reply','المراسلات','جواب على صادر',
    jsonb_build_object('mail',p_mail),st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;
