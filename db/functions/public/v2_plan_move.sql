-- public.v2_plan_move(p_plan uuid, p_lesson uuid, p_week smallint, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d847b135b782cd3e78f899ce078e8153
CREATE OR REPLACE FUNCTION public.v2_plan_move(p_plan uuid, p_lesson uuid, p_week smallint, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record; v_exam smallint; v_ok boolean; v_title text; v_old smallint;
begin
  select * into g from v2.plan_guard(p_plan,'نقلَ بندٍ في التوزيع');
  if btrim(coalesce(p_why,'')) = '' then
    raise exception 'سببُ النقل مطلوبٌ — فالتوزيعُ يُعدَّل بأثرِ الإنجاز وتحليل النواتج لا بالمزاج';
  end if;

  select min(x.week_no) into v_exam from v2.school_weeks(g.school_id) x
   where x.term_no=g.term_no and x.is_exam;

  select true into v_ok from v2.school_weeks(g.school_id) x
   where x.term_no=g.term_no and x.week_no=p_week and not x.is_exam
     and (v_exam is null or x.week_no < v_exam) limit 1;

  if not coalesce(v_ok,false) then
    if v_exam is not null and p_week >= v_exam then
      raise exception 'الأسبوعُ % أسبوعُ اختبارِ نهاية الفصل أو بعده — ولا يُوضع فيه درسٌ ولا بند. وينتهي المنهجُ في الأسبوع %',
        p_week, v_exam - 1;
    end if;
    raise exception 'لا أسبوعَ بالرقم % في الفصل % من تقويم مدرستك', p_week, g.term_no;
  end if;

  select l.title_ar, i.week_no into v_title, v_old
    from v2.lesson_plan_items i join v2.curriculum_lessons l on l.id=i.lesson_id
   where i.plan_id=p_plan and i.lesson_id=p_lesson;
  if v_title is null then raise exception 'هذا البندُ ليس في هذي الخطّة'; end if;

  update v2.lesson_plan_items
     set week_no = p_week, moved_by = v2.current_person(), moved_at = now(),
         move_why = btrim(p_why)
   where plan_id=p_plan and lesson_id=p_lesson;

  return jsonb_build_object('ok',true,'week_no',p_week,'was',v_old,
    'summary_ar','نُقل «'||v_title||'» إلى الأسبوع '||p_week
      ||case when v_old is not null then ' (كان في '||v_old||')' else '' end,
    'note_ar','وسببُ النقل مُسجَّلٌ باسمك ووقته.');
end $function$
;
