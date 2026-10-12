-- v2.threshold_ar(p_count smallint, p_days smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d43d80ae08ea76ff6af8fdd2e5670e83
CREATE OR REPLACE FUNCTION v2.threshold_ar(p_count smallint, p_days smallint)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when p_count is null then null
    when coalesce(p_days,0) = 0
      then 'عتبتُها '||v2.ar_count(p_count,'مرّةً واحدة','مرّتين','مرّات','مرّة')||' بلا مدّةٍ محدّدة'
    else 'عتبتُها '||v2.ar_count(p_count,'مرّةً واحدة','مرّتين','مرّات','مرّة')||
         ' في '||v2.ar_count(p_days,'يومٍ واحد','يومين','أيّام','يومًا') end
$function$
;
