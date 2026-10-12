-- v2.ar_left(n numeric)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5f7cec2e741d1b3d8df4ba45069b7364
CREATE OR REPLACE FUNCTION v2.ar_left(n numeric)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when coalesce(n,0) <= 0 then 'بلغ سقفَه هذا الأسبوع'
              else 'بقي من سقفه '||v2.ar_count(n,'نقطةٌ واحدة','نقطتان','نقاط','نقطة') end
$function$
;
