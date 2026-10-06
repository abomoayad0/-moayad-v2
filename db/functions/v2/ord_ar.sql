-- v2.ord_ar(n integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1f29435060ec4f4757e2326d4d5f8b18
CREATE OR REPLACE FUNCTION v2.ord_ar(n integer)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case n when 1 then 'الأولى' when 2 then 'الثانية' when 3 then 'الثالثة'
                when 4 then 'الرابعة' when 5 then 'الخامسة' when 6 then 'السادسة'
                when 7 then 'السابعة' when 8 then 'الثامنة' when 9 then 'التاسعة'
                when 10 then 'العاشرة' else 'رقم '||v2.ar_num(n) end;
$function$
;
