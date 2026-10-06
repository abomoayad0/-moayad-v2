-- v2.fn_norm_ar(p text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ade824146778cbface7a432393d6f7c7
CREATE OR REPLACE FUNCTION v2.fn_norm_ar(p text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'v2', 'public'
AS $function$
  select nullif(btrim(regexp_replace(
    translate(
      regexp_replace(coalesce(p,''), '[\u0617-\u061A\u064B-\u0652\u0640]', '', 'g'),
      'أإآٱىةؤئ', 'اااايهوي'),
    '\s+', ' ', 'g')), '');
$function$
;
