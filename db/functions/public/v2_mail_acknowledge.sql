-- public.v2_mail_acknowledge(p_mail uuid, p_signed boolean, p_refuse_reason text, p_attachment_name text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e9dac3566b1443ccbd7e98d137631e37
CREATE OR REPLACE FUNCTION public.v2_mail_acknowledge(p_mail uuid, p_signed boolean DEFAULT true, p_refuse_reason text DEFAULT NULL::text, p_attachment_name text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record; v_me uuid; n_rem integer;
begin
  select * into m from v2.incoming_mail where id=p_mail;
  if m.id is null then raise exception 'الواردُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'الإقرار بالاطّلاع');
  if m.secrecy <> 'عادي' and not v2.may_read_secret_mail() then
    raise exception 'هذا واردٌ % — ولا يُقرُّ به إلّا من يحقُّ له قراءتُه', m.secrecy;
  end if;
  v_me := v2.current_person();
  if v_me is null then raise exception 'لا يُعرف المقرُّ — ولا يُسجَّل إقرارٌ بلا اسم'; end if;

  if p_signed and coalesce(btrim(p_attachment_name),'') = '' then
    raise exception 'التوقيعُ يلزمه مرفق — وإن لم يكن لك مرفقٌ فامتنع بسببٍ مكتوبٍ وتتمّ الخطوة';
  end if;
  if not p_signed and coalesce(btrim(p_refuse_reason),'') = '' then
    raise exception 'الامتناعُ عن الإقرار لا يقع بلا سببٍ مكتوب';
  end if;
  if exists (select 1 from v2.mail_acknowledgements a
              where a.mail_id=p_mail and a.person_id=v_me and (a.signed or a.refused)) then
    raise exception 'أقررتَ بهذا الوارد سلفًا — ولا يُقرُّ به مرّتين';
  end if;

  insert into v2.mail_acknowledgements(mail_id,person_id,seen_at,signed,signed_at,
      sign_kind,attachment_ref,refused,refuse_reason)
  values (p_mail,v_me,now(),p_signed, case when p_signed then now() end,
      case when p_signed then 'in_app' end,
      nullif(btrim(p_attachment_name),''), not p_signed, nullif(btrim(p_refuse_reason),''));

  select count(*) into n_rem from v2.mail_items i
    join v2.mail_targets t on t.item_id=i.id
   where i.mail_id=p_mail and t.person_id is not null
     and not exists (select 1 from v2.mail_acknowledgements a
                      where a.mail_id=p_mail and a.person_id=t.person_id
                        and (a.signed or a.refused));

  perform v2.log_action(m.school_id,null,'mail_ack',
    case when p_signed then 'أُقرَّ بالاطّلاع على وارد' else 'وُثّق الامتناعُ عن الإقرار' end,
    'incoming_mail',p_mail, jsonb_build_object('signed',p_signed));

  return jsonb_build_object('ok', true, 'signed', p_signed,
    'note_ar', case when p_signed
        then 'سُجّل إقرارُك بالاطّلاع ومعه مرفقُك'
        else 'وُثّق امتناعُك وسببُه مكتوبٌ باسمك — والخطوةُ تتمّ' end ||
      case when n_rem > 0 then ' · وبقي '||
        v2.ar_count(n_rem,'موجَّهٌ إليه واحدٌ لم يُقرّ','موجَّهان لم يُقرّا',
                          'موجَّهين لم يُقرّوا','موجَّهًا لم يُقرّ')
      else ' · وأقرَّ الموجَّهُ إليهم كلُّهم' end);
end $function$
;
