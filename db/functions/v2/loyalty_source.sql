-- v2.loyalty_source(p_school uuid, p_code text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c8456e512a2b6306c6b994abe8859793
CREATE OR REPLACE FUNCTION v2.loyalty_source(p_school uuid, p_code text)
 RETURNS v2.loyalty_sources
 LANGUAGE sql
 STABLE
AS $function$
  select * from v2.loyalty_sources
   where code = p_code and active and (school_id = p_school or school_id is null)
   order by (school_id is null)          -- مصدرُ المدرسة يُقدَّم على الافتراضيّ
   limit 1
$function$
;
