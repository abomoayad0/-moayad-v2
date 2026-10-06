-- public.v2_exception_add(p_school uuid, p_rule_kind text, p_rule_ref text, p_system_says text, p_school_does text, p_reason text, p_source text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5e038b70596a83d19dac75ff7bc4acd2
CREATE OR REPLACE FUNCTION public.v2_exception_add(p_school uuid, p_rule_kind text, p_rule_ref text, p_system_says text, p_school_does text, p_reason text, p_source text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; yid uuid;
begin
  -- 🔒 الاستثناءُ مخالفةٌ للنظام — فلا يقرّرها إلا المدير
  perform v2.assert_role(array['principal'],'تقييدَ استثناءٍ على النظام');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_system_says,''))='' then
    raise exception 'اكتب ما يقوله النظام'; end if;
  if btrim(coalesce(p_school_does,''))='' then
    raise exception 'اكتب ما تفعله مدرستُك'; end if;
  if btrim(coalesce(p_reason,''))='' then
    raise exception 'لا يُقيَّد استثناءٌ بلا سببٍ مكتوب — فهو مخالفةٌ موثَّقة'; end if;

  select year_id into yid from v2.enrolments e
   where e.school_id=p_school and e.status='active' limit 1;
  insert into v2.exceptions(school_id,rule_kind,rule_ref,system_says,school_does,
      reason,decided_by,decided_at,source_page,year_id)
  values (p_school,p_rule_kind,p_rule_ref,btrim(p_system_says),btrim(p_school_does),
      btrim(p_reason),v2.current_person(),now(),p_source,yid)
  returning id into nid;
  return jsonb_build_object('ok',true,'exception',nid,
    'note','قُيّد الاستثناءُ باسمك وتاريخه — ولا يُمحى');
end $function$
;
