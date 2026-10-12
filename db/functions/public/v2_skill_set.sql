-- public.v2_skill_set(p_school uuid, p_subject text, p_title text, p_kind text, p_grade smallint, p_code text, p_ord integer, p_source text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 edaac1974f657ae0af1fc47a2f5b1f27
CREATE OR REPLACE FUNCTION public.v2_skill_set(p_school uuid, p_subject text, p_title text, p_kind text, p_grade smallint DEFAULT NULL::smallint, p_code text DEFAULT NULL::text, p_ord integer DEFAULT 0, p_source text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_id uuid; v_gf int; v_gt int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','admin_assistant'],
    'إدخالَ مهارةٍ في قائمة المدرسة');
  perform v2.assert_my_school(p_school,'إدخالَ مهارةٍ في قائمة المدرسة');
  if p_kind not in ('minimum','targeted') then
    raise exception 'نوعُ المهارة: حدٌّ أدنى (minimum) أو مستهدفة (targeted)'; end if;
  if btrim(coalesce(p_subject,'')) = '' or btrim(coalesce(p_title,'')) = '' then
    raise exception 'اكتب المادّةَ واسمَ المهارة'; end if;
  v_gf := v2.rule_n(p_school,'reading_grade_from');
  v_gt := v2.rule_n(p_school,'reading_grade_to');

  insert into v2.skills(school_id,subject_ar,grade,code,title_ar,kind,ord,source_ar,created_by,is_test)
  values (p_school,btrim(p_subject),p_grade,nullif(btrim(coalesce(p_code,'')),''),
      btrim(p_title),p_kind,coalesce(p_ord,0),nullif(btrim(coalesce(p_source,'')),''),
      v2.current_person(),
      coalesce((select test_mode from v2.schools where id=p_school),false))
  on conflict (school_id, subject_ar, coalesce(grade, 0::smallint), title_ar) where voided_at is null
  do update set kind=excluded.kind, ord=excluded.ord, code=excluded.code,
      source_ar=coalesce(excluded.source_ar, v2.skills.source_ar), active=true
  returning id into v_id;

  return jsonb_build_object('ok',true,'skill',v_id,
    'summary_ar','أُدخلت «'||btrim(p_title)||'» في '||btrim(p_subject)||
      case when p_grade is null then ' (لكلّ الصفوف)' else ' · الصفُّ '||v2.ar_num(p_grade) end||
      case when p_kind='minimum' then ' · حدٌّ أدنى' else ' · مستهدفة' end,
    'note_ar','وقائمةُ المهارات مدخلٌ لا اختراع — '||v2.cite_of('assess.inputs')||
      case when p_grade is not null and p_grade not between v_gf and v_gt
           then ' · 🟠 وهذا الصفُّ خارجَ نطاق الاستقطاع ('||v2.ar_num(v_gf)||'–'||v2.ar_num(v_gt)||') فلا تُقاس فيه في العشر دقائق'
           else '' end);
end $function$
;
