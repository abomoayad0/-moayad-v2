-- v2.enrol_reason_ar(k text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5baca209cb69230176af74efd971dec1
CREATE OR REPLACE FUNCTION v2.enrol_reason_ar(k text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case k
    when 'transferred' then 'نقل'
    when 'graduated'   then 'تخرّج'
    when 'withdrawn'   then 'طيّ قيد'
    when 'deceased'    then 'وفاة'
    when 'year_closed' then 'إقفال عام'
    when 'suspended'   then 'إيقاف'
    when 'absent_long' then 'انقطاع'
    when 'travel'      then 'سفر'
    when 'other'       then 'أخرى'
    else k end;
$function$
;
