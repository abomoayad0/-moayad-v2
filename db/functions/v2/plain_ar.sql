-- v2.plain_ar(t text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 020432b6894a0a284a2cc3a2882c7d7e
CREATE OR REPLACE FUNCTION v2.plain_ar(t text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select translate(regexp_replace(coalesce(t,''),'[ًٌٍَُِّْـ]','','g'),'إأآىة','اااية');
$function$
;
