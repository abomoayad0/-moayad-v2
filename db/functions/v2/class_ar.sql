-- v2.class_ar(p_grade smallint, p_section text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c0c81ad35219f3ccf9bf2daf7d26ee05
CREATE OR REPLACE FUNCTION v2.class_ar(p_grade smallint, p_section text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case when p_grade is null then null
              when coalesce(btrim(p_section),'') = '' then v2.grade_ar(p_grade)
              else v2.grade_ar(p_grade)||' — '||btrim(p_section) end
$function$
;
