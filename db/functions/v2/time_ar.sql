-- v2.time_ar(t time without time zone)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a177a31b51577519868d83b241b622ae
CREATE OR REPLACE FUNCTION v2.time_ar(t time without time zone)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when t is null then null
    else translate(to_char(t,'HH24:MI'),'0123456789','٠١٢٣٤٥٦٧٨٩') end;
$function$
;
