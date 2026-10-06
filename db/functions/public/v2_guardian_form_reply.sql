-- public.v2_guardian_form_reply(p_inbox uuid, p_reply text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f77c07b579c5be31decd137102417e0a
CREATE OR REPLACE FUNCTION public.v2_guardian_form_reply(p_inbox uuid, p_reply text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare fi record; fno smallint; opts text[];
begin
  select * into fi from v2.form_inbox where id=p_inbox
    and guardian_id in (select id from v2.guardians where user_id=auth.uid() and portal_active);
  if fi.id is null then raise exception 'هذا النموذج ليس في صندوقك'; end if;
  if fi.replied_at is not null then raise exception 'أجبتَ عليه سلفًا'; end if;
  select e.form_no into fno from v2.form_entries e where e.id=fi.entry_id;
  select options into opts from v2.form_schema where form_no=fno and key='guardian_reply';
  if opts is null then raise exception 'هذا النموذج لا ينتظر ردًّا'; end if;
  if not (p_reply = any (opts)) then
    raise exception 'ردّ غير مقبول. والخيارات: %', array_to_string(opts,' · '); end if;
  update v2.form_inbox set replied_at=now(), reply=p_reply, reply_note=p_note,
    read_at=coalesce(read_at,now()) where id=p_inbox;
  return jsonb_build_object('ok',true,'reply',p_reply);
end $function$
;
