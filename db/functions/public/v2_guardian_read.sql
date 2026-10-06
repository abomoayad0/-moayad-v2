-- public.v2_guardian_read(p_event uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a5f3b00e3676c4b685a76c55b168a9fc
CREATE OR REPLACE FUNCTION public.v2_guardian_read(p_event uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  update v2.event_deliveries set read_at=now()
   where event_id=p_event and channel='guardian_portal'
     and to_guardian in (select id from v2.guardians where user_id=auth.uid() and portal_active)
     and read_at is null;
end $function$
;
