-- public.v2_guardian_form_note(p_inbox uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 30dd0bdcf026167f892c584fe79059e0
CREATE OR REPLACE FUNCTION public.v2_guardian_form_note(p_inbox uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare fi record;
begin
  if btrim(coalesce(p_note,''))='' then raise exception 'اكتب رأيك'; end if;
  select * into fi from v2.form_inbox where id=p_inbox
    and guardian_id in (select id from v2.guardians where user_id=auth.uid() and portal_active);
  if fi.id is null then raise exception 'هذا النموذج ليس في صندوقك'; end if;
  update v2.form_entries set guardian_note=p_note, updated_at=now() where id=fi.entry_id;
  update v2.form_inbox set read_at=coalesce(read_at,now()) where id=p_inbox;
  return jsonb_build_object('ok',true);
end $function$
;
