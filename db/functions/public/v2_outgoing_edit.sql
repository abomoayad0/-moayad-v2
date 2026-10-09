-- public.v2_outgoing_edit(p_mail uuid, p_subject text, p_to_entity text, p_body text, p_kind text, p_secrecy text, p_needs_reply boolean, p_reply_due date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 434f2ba1d04ad8bbf1d3d5633922bad8
CREATE OR REPLACE FUNCTION public.v2_outgoing_edit(p_mail uuid, p_subject text DEFAULT NULL::text, p_to_entity text DEFAULT NULL::text, p_body text DEFAULT NULL::text, p_kind text DEFAULT NULL::text, p_secrecy text DEFAULT NULL::text, p_needs_reply boolean DEFAULT NULL::boolean, p_reply_due date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; v_needs boolean; v_due date;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'تعديل مسوّدة الصادر');
  select * into m from v2.outgoing_mail where id=p_mail;
  if m.id is null then raise exception 'الخطابُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'تعديل مسوّدة الصادر');
  if m.status <> 'draft' then
    raise exception 'لا يُعدَّل إلّا ما كان مسوّدةً — وحالُ هذا: %',
      v2.outgoing_state_ar(m.status, m.needs_reply, m.cancel_reason);
  end if;
  if p_subject is not null and btrim(p_subject) = '' then
    raise exception 'موضوعُ الخطاب لا يُترك فارغًا'; end if;
  if p_to_entity is not null and btrim(p_to_entity) = '' then
    raise exception 'الجهةُ المرسلُ إليها لا تُترك فارغةً'; end if;

  v_needs := coalesce(p_needs_reply, m.needs_reply);
  v_due   := coalesce(p_reply_due, m.reply_due_on);
  if v_needs and v_due is null then
    raise exception 'إن كان الخطابُ ينتظر جوابًا فلا بدَّ من موعدٍ يُراجَع عليه';
  end if;

  update v2.outgoing_mail set
      subject_ar  = coalesce(nullif(btrim(p_subject),''), subject_ar),
      to_entity   = coalesce(nullif(btrim(p_to_entity),''), to_entity),
      body_ar     = coalesce(p_body, body_ar),
      kind        = coalesce(p_kind, kind),
      secrecy     = coalesce(p_secrecy, secrecy),
      needs_reply = v_needs,
      reply_due_on = case when v_needs then v_due else null end
   where id = p_mail;

  perform v2.log_action(m.school_id,null,'outgoing_edit','عُدّلت مسوّدةُ صادر',
    'outgoing_mail',p_mail,'{}'::jsonb);

  return v2.outgoing_card(p_mail) || jsonb_build_object('ok',true,
    'note_ar','عُدّلت المسوّدة — ولا رقمَ صادرٍ لها حتّى يُوقّعها المدير');
end $function$
;
