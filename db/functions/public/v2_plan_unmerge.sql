-- public.v2_plan_unmerge(p_plan uuid, p_lesson uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d1a55bc38fbee043ecce5577c3b55cb1
CREATE OR REPLACE FUNCTION public.v2_plan_unmerge(p_plan uuid, p_lesson uuid, p_why text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record; v_title text; v_had uuid;
begin
  select * into g from v2.plan_guard(p_plan,'فصلَ بندٍ مدموج');
  select l.title_ar, i.merged_into into v_title, v_had
    from v2.lesson_plan_items i join v2.curriculum_lessons l on l.id=i.lesson_id
   where i.plan_id=p_plan and i.lesson_id=p_lesson;
  if v_title is null then raise exception 'هذا البندُ ليس في هذي الخطّة'; end if;
  if v_had is null then raise exception '«%» غيرُ مدموجٍ أصلًا', v_title; end if;

  update v2.lesson_plan_items
     set merged_into = null, merged_by = v2.current_person(), merged_at = now(),
         merge_why = coalesce(nullif(btrim(coalesce(p_why,'')),''),'فُصل عن الدمج')
   where plan_id=p_plan and lesson_id=p_lesson;

  return jsonb_build_object('ok',true,
    'summary_ar','فُصل «'||v_title||'» عن الدمج — ويحتاج حصّةً خاصّةً به',
    'note_ar','وقد يعود النقصُ بعد الفصل — فراجِع مخارجَه.');
end $function$
;
