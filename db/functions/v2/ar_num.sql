-- v2.ar_num(n numeric)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0b958aa4bbb4335317b59c814f896987
CREATE OR REPLACE FUNCTION v2.ar_num(n numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select replace(
    translate(rtrim(rtrim(to_char(n,'FM999999990.999'),'0'),'.'),
              '0123456789','٠١٢٣٤٥٦٧٨٩'),
    '.', '٫');
$function$
;
