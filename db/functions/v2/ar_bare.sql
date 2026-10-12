-- v2.ar_bare(p_in text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 67d1710e458f5932005137ee464d9db1
CREATE OR REPLACE FUNCTION v2.ar_bare(p_in text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select btrim(regexp_replace(regexp_replace(coalesce(p_in,''),
    '[ًٌٍَُِّْـٰ]', '', 'g'), '\s+', ' ', 'g'))
$function$
;
