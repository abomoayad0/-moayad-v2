-- v2.caller_is_server()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1d2bfa17e672732c53de12e507964611
CREATE OR REPLACE FUNCTION v2.caller_is_server()
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
declare v_role text;
begin
  begin
    v_role := nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role';
  exception when others then v_role := null;
  end;
  return coalesce(v_role,'') = 'service_role';
end $function$
;
