-- v2.ar_num(n numeric)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 17ed715e9c360bd2b7ee57abf90b4b03
CREATE OR REPLACE FUNCTION v2.ar_num(n numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select translate(rtrim(rtrim(to_char(n,'FM999999990.999'),'0'),'.'),
                   '0123456789','٠١٢٣٤٥٦٧٨٩');
$function$
;
