-- v2.g_guest_no_vote()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2eb6a7f0d223649318d5d98aed979c16
CREATE OR REPLACE FUNCTION v2.g_guest_no_vote()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  if new.invited_as = 'مستدعى' then
    new.can_vote := false;
    new.seat_role := null;
  end if;
  return new;
end $function$
;
