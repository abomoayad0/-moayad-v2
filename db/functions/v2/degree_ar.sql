-- v2.degree_ar(n integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a83987319b249a14ea746956b323a006
CREATE OR REPLACE FUNCTION v2.degree_ar(n integer)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case n when 1 then 'الدرجة الأولى' when 2 then 'الدرجة الثانية'
                when 3 then 'الدرجة الثالثة' when 4 then 'الدرجة الرابعة'
                when 5 then 'الدرجة الخامسة' else 'الدرجة '||n end;
$function$
;
