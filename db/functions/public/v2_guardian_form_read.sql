-- public.v2_guardian_form_read(p_inbox uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 577616aa72ec569591c5a768b84b3ac1
CREATE OR REPLACE FUNCTION public.v2_guardian_form_read(p_inbox uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  update v2.form_inbox set read_at=now() where id=p_inbox and read_at is null
    and guardian_id in (select id from v2.guardians where user_id=auth.uid() and portal_active);
end $function$
;
