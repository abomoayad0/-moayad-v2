-- v2.exit_where_ar(p text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 eafac2309e204cca0034a8d9cd9640c8
CREATE OR REPLACE FUNCTION v2.exit_where_ar(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case p
    when 'restroom'  then 'دورةُ المياه'
    when 'counselor' then 'الموجّه الطلابيّ'
    when 'deputy'    then 'وكيلُ شؤون الطلبة'
    when 'principal' then 'مديرُ المدرسة'
    when 'health'    then 'الموجّه الصحّيّ'
    when 'admin'     then 'الإدارة'
    when 'activity'  then 'نشاط'
    else 'أخرى' end;
$function$
;
