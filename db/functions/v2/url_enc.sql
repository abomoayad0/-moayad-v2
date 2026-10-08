-- v2.url_enc(t text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d4c4d71330365fca0ecd71ad6c273605
CREATE OR REPLACE FUNCTION v2.url_enc(t text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select string_agg(
    case when b ~ '^[A-Za-z0-9._~-]$' then b
         else regexp_replace(upper(encode(convert_to(b,'UTF8'),'hex')),
                             '(..)', '%\1', 'g') end, '')
  from (select regexp_split_to_table(coalesce(t,''),'') b) x;
$function$
;
