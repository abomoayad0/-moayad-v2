-- v2.owner_ar(p text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 205b889f78aeb3dfdbf43eb6e11f1da8
CREATE OR REPLACE FUNCTION v2.owner_ar(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when p is null then null
    when p ~ '^[a-z_]+$' then coalesce(v2.role_ar(p), p)
    else p end;
$function$
;
