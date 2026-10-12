-- public.v2_plan_approve(p_plan uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c6d9fa54cf9da7cd64176a9bbf574263
CREATE OR REPLACE FUNCTION public.v2_plan_approve(p_plan uuid, p_why text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record; v_status text; v_no_review boolean := false; v_unplaced int;
begin
  select * into g from v2.plan_guard(p_plan,'اعتمادَ التوزيع');
  perform v2.assert_role(array['deputy_academic','deputy','deputy_school','principal'],
    'اعتمادَ التوزيع');
  if v2.current_person() = g.owner_person then
    raise exception 'لا يعتمد المعلّمُ توزيعَ نفسه';
  end if;

  select status into v_status from v2.lesson_plans where id=p_plan;
  if v_status = 'draft' then
    raise exception 'مسوّدةٌ لم يُعلن المعلّمُ إعدادَها — ولا تُعتمد مسوّدة';
  end if;
  if v_status = 'approved' then raise exception 'معتمدٌ من قبل'; end if;

  select count(*) into v_unplaced from v2.lesson_plan_items
   where plan_id=p_plan and week_no is null;
  if v_unplaced > 0 then
    raise exception '% بندًا بلا أسبوعٍ — ولا يُعتمد توزيعٌ ناقص. وانظر مخارجَ النقص', v_unplaced;
  end if;

  if v_status <> 'reviewed' then
    if btrim(coalesce(p_why,'')) = '' then
      raise exception 'هذا التوزيعُ لم يُراجَع — والاعتمادُ بلا مراجعةٍ يحتاج سببًا مكتوبًا، ويُوسم في لوحتك';
    end if;
    v_no_review := true;
  end if;

  update v2.lesson_plans
     set status='approved', approved_by=v2.current_person(), approved_at=now(),
         approved_without_review=v_no_review,
         note_ar = case when v_no_review
            then concat_ws(' · ', note_ar, 'اعتُمد بلا مراجعة: '||btrim(p_why)) else note_ar end
   where id=p_plan;

  return jsonb_build_object('ok',true,'status','approved','without_review',v_no_review,
    'summary_ar','اعتُمد توزيعُ «'||g.subject_ar||'» للصفّ '||g.grade
      ||case when v_no_review then ' — 🟠 بلا مراجعة' else '' end,
    'note_ar','وصار «الخطّةَ الفصليّةَ المعتمدة» بنصّ الدليل. '
      ||case when v_no_review then 'ويُعرض موسومًا في لوحتك بعددٍ، ولا يُخفى.' else '' end);
end $function$
;
