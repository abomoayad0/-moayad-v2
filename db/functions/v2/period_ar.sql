-- v2.period_ar(n smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6603cf2906c84a07632d99e4ecc54d1f
CREATE OR REPLACE FUNCTION v2.period_ar(n smallint)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case n
    when 1 then 'الحصّة الأولى'   when 2 then 'الحصّة الثانية' when 3 then 'الحصّة الثالثة'
    when 4 then 'الحصّة الرابعة'  when 5 then 'الحصّة الخامسة' when 6 then 'الحصّة السادسة'
    when 7 then 'الحصّة السابعة'  when 8 then 'الحصّة الثامنة' when 9 then 'الحصّة التاسعة'
    when 10 then 'الحصّة العاشرة' when 11 then 'الحصّة الحادية عشرة' when 12 then 'الحصّة الثانية عشرة'
    else case when n is null then null else 'الحصّة '||v2.ar_num(n) end end
$function$
;
