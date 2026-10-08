-- v2.conduct_mode_ar(p_mode text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7245e165d779d14d305665a5a0086713
CREATE OR REPLACE FUNCTION v2.conduct_mode_ar(p_mode text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO ''
AS $function$
  select case p_mode when 'online' then 'التعليمُ عن بُعد'
                     when 'onsite' then 'التعليمُ الحضوريّ' else coalesce(p_mode,'—') end;
$function$
;
