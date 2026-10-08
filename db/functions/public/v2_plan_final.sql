-- public.v2_plan_final(p_plan uuid, p_confirm text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c4aae17e9102ebde4ab9f0cb67825ec2
CREATE OR REPLACE FUNCTION public.v2_plan_final(p_plan uuid, p_confirm text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record;
begin
  perform v2.assert_role(array['counselor','deputy_students','deputy','principal'],
                         'اعتمادَ خطّة تعديل السلوك');
  select * into cur from v2.behavior_plans where id=p_plan;
  if cur.id is null then raise exception 'الخطّةُ غيرُ موجودة'; end if;
  if cur.status='final' then raise exception 'اعتُمدت هذي الخطّةُ سلفًا'; end if;
  if btrim(coalesce(cur.target_behavior,''))='' or coalesce(array_length(cur.steps,1),0)=0 then
    raise exception 'لا تُعتمد خطّةٌ بلا سلوكٍ مستهدفٍ وإجراءاتِ تعديل'; end if;
  if cur.teacher_opinion is null then
    raise exception 'لم يُبدِ معلّمُ الفصل رأيَه بعد — والخطّةُ تُبنى على ما يراه في الصفّ'; end if;
  -- 🔑 إقرارٌ صريح: بالاعتماد يبدأ قياسُ الاستجابة، وعليه تُبنى الإحالة
  if btrim(coalesce(p_confirm,'')) <> 'أعتمد' then
    raise exception 'باعتماد الخطّة يبدأ قياسُ استجابة الطالب، وعليه تُبنى إحالتُه للّجنة — اكتب «أعتمد» لتأكيده'; end if;

  update v2.behavior_plans set status='final', final_at=now(), final_by=v2.current_person()
   where id=p_plan;

  if cur.task_id is not null then
    update v2.behavior_tasks set status='done', done_at=now(), done_by=v2.current_person(),
      ev_on=current_date, ev_text='اعتُمدت خطّةُ تعديل السلوك (نموذج ٣)'
     where id=cur.task_id and status<>'done';
  end if;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (coalesce(cur.school_id,(select e.school_id from v2.enrolments e
            where e.student_id=cur.student_id and e.status='active' limit 1)),
      'other',current_date,cur.student_id,
      'اعتُمدت خطّةُ تعديل السلوك',
      'السلوكُ المستهدف: '||cur.target_behavior,
      'behavior_plans',p_plan,'all',coalesce(cur.is_test,false));

  perform v2.log_action(cur.school_id,cur.student_id,'plan_final',
    'اعتُمدت خطّةُ تعديل السلوك','behavior_plans',p_plan,
    jsonb_build_object('target',cur.target_behavior));
  return jsonb_build_object('ok',true,
    'note','اعتُمدت الخطّةُ — ومن اليوم يُقاس أثرُها: فإن رُصد بعدها لم يتعدّل، وإن لم يُرصد تعدّل');
end $function$
;
