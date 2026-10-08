-- public.v2_outgoing_cancel(p_mail uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4e9e4cec22a439690795fceaf396dcc0
CREATE OR REPLACE FUNCTION public.v2_outgoing_cancel(p_mail uuid, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; n integer := 0; msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['principal','deputy'],'إلغاء صادر');
  select * into m from v2.outgoing_mail where id = p_mail;
  if m.id is null then raise exception 'الخطابُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'إلغاء صادر');
  if coalesce(btrim(p_why),'') = '' then
    raise exception 'الإلغاءُ يلزمه سببٌ مكتوبٌ يبقى في السجلّ باسمك';
  end if;
  if m.status in ('sent','replied','closed') then
    raise exception 'ما خرج من المدرسة لا يُلغى من السجلّ — '
      'فالجهةُ قد قرأته · ويُستدرك بخطابٍ صادرٍ بعده يُحيل إلى رقمه';
  end if;
  if m.status = 'cancelled' then raise exception 'ملغًى سلفًا'; end if;

  update v2.outgoing_mail set status='cancelled', cancel_reason=btrim(p_why) where id = p_mail;

  update v2.behavior_tasks set auto_note =
      'أُلغي الخطابُ الذي كان يحمله — والسببُ: '||btrim(p_why)||
      ' · فالبندُ يحتاج خطابًا آخر، ويعود في «ما ينتظر الصادر»'
   where id in (select task_id from v2.outgoing_mail_tasks where mail_id = p_mail)
     and status <> 'done';

  select count(*) into n from v2.outgoing_mail_tasks lt
    join v2.behavior_tasks bt on bt.id = lt.task_id
   where lt.mail_id = p_mail and bt.status <> 'done';

  perform v2.log_action(m.school_id,null,'outgoing_cancel','أُلغي خطابٌ صادر',
    'outgoing_mail',p_mail, jsonb_build_object('why',btrim(p_why),'freed',n));

  return v2.outgoing_card(p_mail) || jsonb_build_object('ok', true,
    'note_ar','أُلغي الخطابُ وبقي في السجلّ موسومًا بالإلغاء وسببِه — ولا يُحذف'||
      case when n > 0 then ' · و'||
        v2.ar_count(n,'بندٌ واحدٌ كان يحمله يعود','بندان كانا يحملانه يعودان',
                      'بنودٍ كانت تحمله تعود','بندًا كان يحمله يعود')||
        ' إلى «ما ينتظر الصادر»' else '' end);
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_outgoing_cancel','المراسلات','إلغاء صادر',
    jsonb_build_object('mail',p_mail),st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;
