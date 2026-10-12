-- v2.ar_count0(n numeric, p_zero text, p_one text, p_two text, p_few text, p_many text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 36cac86525a836b24a4d8d5bf3f0aca3
CREATE OR REPLACE FUNCTION v2.ar_count0(n numeric, p_zero text, p_one text, p_two text, p_few text, p_many text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when coalesce(n,0) = 0 then p_zero else v2.ar_count(n, p_one, p_two, p_few, p_many) end
$function$
;
