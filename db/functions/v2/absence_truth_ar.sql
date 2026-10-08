-- v2.absence_truth_ar(p_v text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f47b36994dcd7e0cdcd0e52b6e78fb8e
CREATE OR REPLACE FUNCTION v2.absence_truth_ar(p_v text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select case p_v
           when 'system' then 'النظامُ هو الأصل — ونورٌ جهةُ مطابقةٍ لا مصدر'
           when 'noor'   then 'نورٌ هو الأصل — والنظامُ يتبعه'
           else p_v end;
$function$
;
