-- v2.record_state_ar(p_status text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 39fc1e934027264f04121c5b4bc2e1da
CREATE OR REPLACE FUNCTION v2.record_state_ar(p_status text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select case p_status
           when 'open'   then 'مفتوحةٌ — بقي فيها بند'
           when 'closed' then 'استوفت بنودَها'
           when 'voided' then 'ملغاة'
           else p_status end;
$function$
;
