-- v2.g_open_case_on_refer()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d2521316ddc3cb6888e70fd319909dce
CREATE OR REPLACE FUNCTION v2.g_open_case_on_refer()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  -- 🔒 مُعطَّلٌ بقرار مفرح ٨/١٠/٢٠٢٦: فتحُ حالة الموجّه بابُه v2.ladder_auto وحدَه
  -- وكان هذا المُثبِّتُ يفتحها خفيةً، فيقول المحرّكُ بعده: «له حالةٌ مفتوحةٌ سلفًا»
  -- وهي رسالةٌ كاذبةٌ على طالبٍ لا حالةَ له
  return new;
end
$function$
;
