-- public.v2_plan_periods(p_plan uuid, p_lesson uuid, p_periods smallint, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f7a2878e79d68e267a03b4a9ee210fbb
CREATE OR REPLACE FUNCTION public.v2_plan_periods(p_plan uuid, p_lesson uuid, p_periods smallint, p_why text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record; v_title text; v_old smallint; v_sc uuid; v_max int;
begin
  select * into g from v2.plan_guard(p_plan,'تعديلَ حصص بندٍ');
  select pl.school_id into v_sc from v2.lesson_plans pl where pl.id=p_plan;
  v_max := v2.rule_n(v_sc,'item_periods_max');
  if p_periods is null or p_periods < 1 or p_periods > v_max then
    raise exception 'حصصُ البند من واحدةٍ إلى %', v2.ar_num(v_max);
  end if;
  select l.title_ar, i.periods into v_title, v_old
    from v2.lesson_plan_items i join v2.curriculum_lessons l on l.id=i.lesson_id
   where i.plan_id=p_plan and i.lesson_id=p_lesson;
  if v_title is null then raise exception 'هذا البندُ ليس في هذي الخطّة'; end if;

  update v2.lesson_plan_items
     set periods = p_periods, moved_by = v2.current_person(), moved_at = now(),
         move_why = coalesce(nullif(btrim(coalesce(p_why,'')),''), move_why)
   where plan_id=p_plan and lesson_id=p_lesson;

  return jsonb_build_object('ok',true,'periods',p_periods,'was',v_old,
    'summary_ar','صار «'||v_title||'» '||v2.ar_count(p_periods,'حصّةً واحدة','حصّتين','حصص','حصّة')
      ||case when v_old is not null and v_old<>p_periods then ' (كان '||v_old||')' else '' end,
    'note_ar','وتغييرُ الحصص يُغيّر سعةَ الأسبوع — فأعِد الحسابَ إن أردت بثًّا متوازنًا.');
end $function$
;
