-- v2.skill_level_of(p_school uuid, p_in text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 31ad46bb5b6a37b81c3fe6dec24bf512
CREATE OR REPLACE FUNCTION v2.skill_level_of(p_school uuid, p_in text)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v text; v_all text; b text;
begin
  if btrim(coalesce(p_in,'')) = '' then raise exception 'اكتب المستوى'; end if;
  b := v2.ar_bare(p_in);

  select l.label_ar into v from v2.skill_levels l
   where l.active and l.school_id = p_school
     and (l.key = btrim(p_in) or v2.ar_bare(l.label_ar) = b) limit 1;
  if v is not null then return v; end if;

  select l.label_ar into v from v2.skill_levels l
   where l.active and l.school_id is null
     and (l.key = btrim(p_in) or v2.ar_bare(l.label_ar) = b) limit 1;
  if v is not null then return v; end if;

  select string_agg(l.label_ar, ' · ' order by l.ord) into v_all from v2.skill_levels l
   where l.active and (l.school_id = p_school or l.school_id is null);
  raise exception 'المستوى «%» ليس في مستويات الإتقان — والمقبولُ: %',
    btrim(p_in), coalesce(v_all,'لا مستوياتَ مُعلَنةً بعد');
end $function$
;
