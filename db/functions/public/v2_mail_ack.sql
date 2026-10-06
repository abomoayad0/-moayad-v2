-- public.v2_mail_ack(p_mail uuid, p_signed boolean, p_refuse_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 71be7568d533e841c5448f14b7046f90
CREATE OR REPLACE FUNCTION public.v2_mail_ack(p_mail uuid, p_signed boolean DEFAULT true, p_refuse_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  select school_id into sc from v2.incoming_mail where id=p_mail;
  perform v2.assert_my_school(sc,'الإقرار بالاطّلاع على الوارد');
  if not p_signed and btrim(coalesce(p_refuse_reason,''))='' then
    raise exception 'الامتناع عن التوقيع لا يقع بلا سبب مكتوب'; end if;
  insert into v2.mail_acknowledgements(mail_id, person_id, seen_at, signed, signed_at,
    sign_kind, refused, refuse_reason)
  values (p_mail, v2.current_person(), now(), p_signed, case when p_signed then now() end,
    'portal', not p_signed, p_refuse_reason);
end $function$
;
