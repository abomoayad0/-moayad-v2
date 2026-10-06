-- v2.fn_acknowledge_mail(p_ack uuid, p_signed boolean, p_kind text, p_refused boolean, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 21b6257aef5a1665ea660bdd79a2d895
CREATE OR REPLACE FUNCTION v2.fn_acknowledge_mail(p_ack uuid, p_signed boolean DEFAULT true, p_kind text DEFAULT 'in_app'::text, p_refused boolean DEFAULT false, p_reason text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if p_refused and btrim(coalesce(p_reason,''))='' then
    raise exception 'رفض الإقرار لا يقع بلا سبب مكتوب'; end if;
  update v2.mail_acknowledgements
     set seen_at = coalesce(seen_at, now()),
         signed = (p_signed and not p_refused),
         signed_at = case when p_signed and not p_refused then now() else null end,
         sign_kind = case when p_signed and not p_refused then p_kind else null end,
         refused = p_refused, refuse_reason = p_reason
   where id = p_ack;
end $function$
;
