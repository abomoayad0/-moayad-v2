-- v2.role_ar(p text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8bdf6b3704e4d1af957a2c6be738632f
CREATE OR REPLACE FUNCTION v2.role_ar(p text)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce((select label_ar from v2.posts where key = p),
    case p when 'owner' then 'مالك النظام' when 'principal' then 'مدير المدرسة'
           when 'duty_officer' then 'المناوب' when 'teacher' then 'معلم'
           when 'staff' then 'منسوب' when 'viewer' then 'مطّلع' else null end)
$function$
;
