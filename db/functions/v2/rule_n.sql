-- v2.rule_n(p_school uuid, p_key text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 fdbf9a67cd2edca87e64025bb28e712d
CREATE OR REPLACE FUNCTION v2.rule_n(p_school uuid, p_key text)
 RETURNS integer
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v integer;
begin
  select r.value_n into v from v2.rule_numbers r
   where r.key = p_key and r.school_id = p_school limit 1;
  if v is not null then return v; end if;
  select r.value_n into v from v2.rule_numbers r
   where r.key = p_key and r.school_id is null limit 1;
  if v is null then
    raise exception 'الرقمُ «%» غيرُ مُعلَنٍ في مرجع الأرقام — ولا يُفترض رقمٌ بلا سند', p_key;
  end if;
  return v;
end $function$
;
