-- public.v2_plan_kind(p_plan uuid, p_lesson uuid, p_kind text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 560172ba83807783065c0003b7de8c9c
CREATE OR REPLACE FUNCTION public.v2_plan_kind(p_plan uuid, p_lesson uuid, p_kind text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record; v_title text; v_base text;
begin
  select * into g from v2.plan_guard(p_plan,'وسمَ نوع بندٍ');
  if btrim(coalesce(p_kind,'')) not in ('lesson','exam','review','intro','project','activity') then
    raise exception 'نوعٌ غيرُ معروف — والمقبولُ: lesson درس · exam اختبار · review مراجعة · intro تهيئة · project مشروع · activity نشاط';
  end if;
  select l.title_ar, coalesce(l.kind,'lesson') into v_title, v_base
    from v2.lesson_plan_items i join v2.curriculum_lessons l on l.id=i.lesson_id
   where i.plan_id=p_plan and i.lesson_id=p_lesson;
  if v_title is null then raise exception 'هذا البندُ ليس في هذي الخطّة'; end if;

  update v2.lesson_plan_items
     set kind_override = btrim(p_kind), kind_by = v2.current_person(), kind_at = now()
   where plan_id=p_plan and lesson_id=p_lesson;

  return jsonb_build_object('ok',true,'kind',btrim(p_kind),'base_kind',v_base,
    'summary_ar','وُسم «'||v_title||'» في خطّتك، وكان في المنهج موسومًا «'||v_base||'»',
    'note_ar','ووسمُ المنهج باقٍ — ووسمُك يُرجَّح في خطّتك وحدَها.');
end $function$
;
