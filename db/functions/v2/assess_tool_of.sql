-- v2.assess_tool_of(p_school uuid, p_in text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ea752328fb8711062ae14414ac68fa5a
CREATE OR REPLACE FUNCTION v2.assess_tool_of(p_school uuid, p_in text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v text; v_all text; b text;
begin
  if btrim(coalesce(p_in,'')) = '' then return null; end if;
  b := v2.ar_bare(p_in);
  select t.key into v from v2.assess_tools t
   where t.active and t.school_id = p_school
     and (t.key = btrim(p_in) or v2.ar_bare(t.label_ar) = b) limit 1;
  if v is not null then return v; end if;
  select t.key into v from v2.assess_tools t
   where t.active and t.school_id is null
     and (t.key = btrim(p_in) or v2.ar_bare(t.label_ar) = b) limit 1;
  if v is not null then return v; end if;
  select string_agg(t.label_ar,' · ' order by t.ord) into v_all from v2.assess_tools t
   where t.active and (t.school_id = p_school or t.school_id is null);
  raise exception 'الأداة «%» ليست في أدوات التقويم — والمقبولُ: %', btrim(p_in), coalesce(v_all,'لا أدواتَ مُعلَنة');
end $function$
;
