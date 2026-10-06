-- v2.can_do(p_allowed text[])
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bb826f0d9b8a9495e91a67d45a1510ca
CREATE OR REPLACE FUNCTION v2.can_do(p_allowed text[])
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(p_allowed,'—');
  return true;
exception when others then return false;
end $function$
;
