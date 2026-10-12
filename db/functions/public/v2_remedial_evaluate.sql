-- public.v2_remedial_evaluate(p_plan uuid, p_improved boolean, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 87ca283ca14242f94b1bc702f08fe4d1
CREATE OR REPLACE FUNCTION public.v2_remedial_evaluate(p_plan uuid, p_improved boolean, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare p record; me uuid := v2.current_person(); v_min int;
begin
  select * into p from v2.remedial_plans where id=p_plan and voided_at is null;
  if p.id is null then raise exception 'لا خطّةَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(p.school_id,'تقييمَ نتائج الخطّة العلاجيّة');
  if not (v2.in_committee(p.school_id,'guidance',me)
          or v2.my_role() in ('principal','deputy','deputy_academic')) then
    raise exception 'تقييمُ نتائج الخطّة للجنة التوجيه الطلابيّ — ولستَ من أعضائها'; end if;
  if p.approved_at is null then
    raise exception 'لا تُقيَّم خطّةٌ لم تُعتمد'; end if;
  v_min := v2.rule_n(p.school_id,'reason_min_chars');
  if length(btrim(coalesce(p_note,''))) < v_min then
    raise exception 'التقييمُ لا يقع بلا نصٍّ — وأقلُّه % حرفًا', v2.ar_num(v_min); end if;

  update v2.remedial_plans
     set improved=p_improved, evaluated_by=me, evaluated_at=now(),
         evaluate_note=btrim(p_note), state='evaluated'
   where id=p_plan;

  return jsonb_build_object('ok',true,'plan',p_plan,'improved',p_improved,
    'summary_ar','قيّمت لجنةُ التوجيه الطلابيّ الخطّةَ — '||
      case when p_improved then 'وتحسّنت الحالة' else 'ولم تتحسّن' end,
    'note_ar','ومؤشّرُ الإجراء نسبةُ التحسّن — '||v2.cite_of('remedial.improve_rate')
      ||case when not p_improved then ' · ومن لم يتمكّن من مهارات الحدّ الأدنى يُنظر في حالته، '
             ||'ومتكرّرو الرسوب يُوصى بتحويلهم إلى أقرب مدرسةٍ للتعليم المستمرّ' else '' end);
end $function$
;
