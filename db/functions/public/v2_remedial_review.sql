-- public.v2_remedial_review(p_plan uuid, p_note text, p_enrich boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f63a6fa9efe3bb92a8692001f5dcedd6
CREATE OR REPLACE FUNCTION public.v2_remedial_review(p_plan uuid, p_note text, p_enrich boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare p record; me uuid := v2.current_person(); v_min int;
begin
  select * into p from v2.remedial_plans where id=p_plan and voided_at is null;
  if p.id is null then raise exception 'لا خطّةَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(p.school_id,'مراجعةَ خطّةٍ علاجيّة');
  if p.kind <> 'group' then
    raise exception 'المراجعةُ للحالات الجماعيّة وحدَها بنصّه: %', v2.cite_of('remedial.group_review'); end if;
  if not (v2.in_committee(p.school_id,'guidance',me)
          or v2.my_role() in ('principal','deputy','deputy_academic')) then
    raise exception 'مراجعةُ الخطّة الجماعيّة للجنة التوجيه الطلابيّ — ولستَ من أعضائها'; end if;
  if p.state in ('approved','running','evaluated') then
    raise exception 'الخطّةُ اعتُمدت — ولا تُراجع بعد الاعتماد'; end if;
  v_min := v2.rule_n(p.school_id,'reason_min_chars');
  if length(btrim(coalesce(p_note,''))) < v_min then
    raise exception 'المراجعةُ لا تقع بلا رأيٍ مكتوبٍ — وأقلُّه % حرفًا', v2.ar_num(v_min); end if;

  update v2.remedial_plans
     set reviewed_by=me, reviewed_at=now(), review_note=btrim(p_note),
         enrich_needed=coalesce(p_enrich,false), state='reviewed'
   where id=p_plan;

  return jsonb_build_object('ok',true,'plan',p_plan,'enrich_needed',coalesce(p_enrich,false),
    'summary_ar','راجعت لجنةُ التوجيه الطلابيّ الخطّةَ'
      ||case when p_enrich then ' · وقرّرت أنّها تحتاج دروسًا إثرائيّةً أو حصصًا أخرى' else '' end,
    'note_ar','ويبقى اعتمادُ الوكيل للشؤون التعليميّة — '||v2.cite_of('remedial.approve'));
end $function$
;
