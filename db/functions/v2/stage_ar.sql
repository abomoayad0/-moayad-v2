-- v2.stage_ar(p text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d9b3fc25c4b2d76320dbcbef28169e0a
CREATE OR REPLACE FUNCTION v2.stage_ar(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case p when 'primary' then 'المرحلة الابتدائية'
                when 'intermediate' then 'المرحلة المتوسطة'
                when 'secondary' then 'المرحلة الثانوية'
                when 'kg' then 'رياض الأطفال' else p end
$function$
;
