-- v2.grade_ar(g smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 975fda8e1146aabd3ac2b1e11abb09b4
CREATE OR REPLACE FUNCTION v2.grade_ar(g smallint)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
 select case g
  when 1 then 'الصف الأول الابتدائي' when 2 then 'الصف الثاني الابتدائي'
  when 3 then 'الصف الثالث الابتدائي' when 4 then 'الصف الرابع الابتدائي'
  when 5 then 'الصف الخامس الابتدائي' when 6 then 'الصف السادس الابتدائي'
  when 7 then 'أول متوسط' when 8 then 'ثاني متوسط' when 9 then 'ثالث متوسط'
  when 10 then 'أول ثانوي' when 11 then 'ثاني ثانوي' when 12 then 'ثالث ثانوي' end
$function$
;
