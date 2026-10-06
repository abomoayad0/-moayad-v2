-- v2.fn_digits(p text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 93c28770e82b3205c45533de77b77669
CREATE OR REPLACE FUNCTION v2.fn_digits(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select regexp_replace(coalesce(p,''), '[^0-9]', '', 'g');
$function$
;
