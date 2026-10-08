-- v2.ar_count(n numeric, p_one text, p_two text, p_few text, p_many text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 50ca54e0747337668aefb3c662971a60
CREATE OR REPLACE FUNCTION v2.ar_count(n numeric, p_one text, p_two text, p_few text, p_many text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select case
           when n is null then null
           when n = 1 then p_one
           when n = 2 then p_two
           when n >= 3 and n <= 10 then v2.ar_num(n)||' '||p_few
           else v2.ar_num(n)||' '||p_many
         end;
$function$
;
