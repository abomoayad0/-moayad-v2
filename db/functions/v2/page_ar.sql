-- v2.page_ar(p text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f8dbe116757668417606f242c1cab80b
CREATE OR REPLACE FUNCTION v2.page_ar(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when p is null then null
    else 'ص'||translate(regexp_replace(p,'[^0-9]','','g'),'0123456789','٠١٢٣٤٥٦٧٨٩') end;
$function$
;
