-- public.v2_reference(p_key text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d04f39603b7bff023d68ced652166b2b
CREATE OR REPLACE FUNCTION public.v2_reference(p_key text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if auth.uid() is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  if v2.my_grant() is null then raise exception 'لا حسابَ فعّالٌ لك في هذا النظام'; end if;

  if p_key = 'absence_ladder' then
    select jsonb_build_object('label','سلّم الغياب','locked',true,
      'source','قواعد السلوك والمواظبة ١٤٤٧',
      'items',(select coalesce(jsonb_agg(jsonb_build_object(
          'ladder',l.ladder_id,'ord',l.ord,'kind',l.kind,'text',l.text_ar,
          'owner',l.owner_role,'origin',l.origin,'evidence',l.evidence_kind)
          order by l.ladder_id, l.ord),'[]'::jsonb) from v2.absence_ladder_items l))
    into r;

  elsif p_key = 'absence_excuses' then
    select jsonb_build_object('label','أعذار الغياب المقبولة','locked',true,
      'source','قواعد السلوك والمواظبة ١٤٤٧',
      'note','وما وُسم «تقديرُ المدرسة» تقرّره لجنةُ التوجيه',
      'items',(select coalesce(jsonb_agg(jsonb_build_object(
          'no',e.item_no,'text',e.text_ar,'proof',e.proof_ar,
          'school_discretion',e.school_discretion,
          'source',e.source_doc||' '||e.source_page) order by e.item_no),'[]'::jsonb)
        from v2.absence_excuses e))
    into r;

  elsif p_key = 'violence_types' then
    select jsonb_build_object('label','أنواع العنف','locked',true,
      'source','الدليل الإجرائي للحماية',
      'items',(select coalesce(jsonb_agg(jsonb_build_object(
          'key',v.key,'family',v.family,'label',v.label_ar,
          'definition',v.definition_ar,'source',v.source_doc||' '||v.source_page)
          order by v.family, v.key),'[]'::jsonb) from v2.violence_types v))
    into r;

  elsif p_key = 'grading' then
    select jsonb_build_object('label','قواعد التقدير والمواد','locked',true,
      'source','لائحة تقويم الطالب',
      'models',(select coalesce(jsonb_agg(to_jsonb(g)),'[]'::jsonb) from v2.grading_models g),
      'subjects',(select coalesce(jsonb_agg(to_jsonb(s)),'[]'::jsonb) from v2.grading_subjects s))
    into r;

  else
    raise exception 'مرجعٌ غيرُ معروف: % — المتاح: absence_ladder · absence_excuses · violence_types · grading', p_key;
  end if;
  return r;
end $function$
;
