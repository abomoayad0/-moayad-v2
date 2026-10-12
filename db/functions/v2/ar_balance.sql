-- v2.ar_balance(n numeric)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 99382ceb465a6ef89ccf2a67a33a2c2d
CREATE OR REPLACE FUNCTION v2.ar_balance(n numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when coalesce(n,0) = 0 then 'لا رصيدَ له'
              else 'رصيدُه '||v2.ar_count(n,'نقطةٌ واحدة','نقطتان','نقاط','نقطة') end
$function$
;
