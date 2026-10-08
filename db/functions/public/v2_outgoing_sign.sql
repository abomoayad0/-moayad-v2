-- public.v2_outgoing_sign(p_mail uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c5033e5af7d6273bd8d9499628a9ce6b
CREATE OR REPLACE FUNCTION public.v2_outgoing_sign(p_mail uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; n integer; msg text; st text; d text; h text; ctx text;
begin
  perform v2.assert_role(array['principal','deputy'],'توقيع الصادر');
  select * into m from v2.outgoing_mail where id = p_mail;
  if m.id is null then raise exception 'الخطابُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'توقيع الصادر');
  if m.status <> 'draft' then
    raise exception 'لا يُوقَّع إلّا ما كان مسوّدةً — وحالُ هذا: %', m.status;
  end if;

  n := v2.next_outgoing_serial(m.school_id, m.year_id);
  update v2.outgoing_mail set status='signed', serial_no=n,
      signed_by=v2.current_person(), signed_at=now(),
      issued_on_g=current_date, issued_on_h=v2.fn_to_hijri(current_date)
   where id = p_mail;

  perform v2.log_action(m.school_id,null,'outgoing_sign','وُقّع خطابٌ صادر',
    'outgoing_mail',p_mail, jsonb_build_object('serial',n));

  return v2.outgoing_card(p_mail) || jsonb_build_object('ok', true,
    'note_ar','وُقّع وأُعطي رقمَ الصادر '||v2.ar_num(n)||
      ' · وبقي إخراجُه وتسجيلُ قناته ومرجعه');
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, d=pg_exception_detail,
    h=pg_exception_hint, ctx=pg_exception_context;
  perform v2.fn_log_error(msg,'v2_outgoing_sign','المراسلات','توقيع صادر',
    jsonb_build_object('mail',p_mail),st,d,h,ctx,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', msg using errcode = st;
end $function$
;
