-- public.v2_plan_write(p_student uuid, p_record uuid, p_task uuid, p_plan uuid, p_desc text, p_manifest text, p_ante text, p_conseq text, p_gain text, p_prior text, p_target text, p_steps text, p_starts date, p_ends date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2609b495dcdd2e1debb78eb2057f15cc
CREATE OR REPLACE FUNCTION public.v2_plan_write(p_student uuid, p_record uuid, p_task uuid, p_plan uuid, p_desc text, p_manifest text, p_ante text, p_conseq text, p_gain text, p_prior text, p_target text, p_steps text, p_starts date, p_ends date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; sc uuid; cur record;
begin
  perform v2.assert_role(array['counselor','deputy_students','deputy','principal'],
                         'كتابةَ خطّة تعديل السلوك');
  perform v2.assert_my_student(p_student,'خطة تعديل السلوك');
  if btrim(coalesce(p_desc,''))='' then raise exception 'صِف السلوكَ المراد تعديلُه'; end if;
  if btrim(coalesce(p_target,''))='' then raise exception 'اكتب السلوكَ البديلَ المستهدف'; end if;
  if btrim(coalesce(p_steps,''))='' then raise exception 'اكتب إجراءاتِ التعديل'; end if;

  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;

  if p_plan is null then
    insert into v2.behavior_plans(school_id,student_id,record_id,task_id,
        problem_desc,manifestations,antecedents,consequences,student_gain,
        prior_actions,target_behavior,steps,starts_on,ends_on,
        status,owner_person,is_test)
    values (sc,p_student,p_record,p_task,
        btrim(p_desc),nullif(btrim(coalesce(p_manifest,'')),''),
        nullif(btrim(coalesce(p_ante,'')),''),nullif(btrim(coalesce(p_conseq,'')),''),
        nullif(btrim(coalesce(p_gain,'')),''),nullif(btrim(coalesce(p_prior,'')),''),
        btrim(p_target),string_to_array(btrim(p_steps),E'\n'),
        coalesce(p_starts,current_date),p_ends,
        'draft',v2.current_person(),
        coalesce((select test_mode from v2.schools where id=sc),false))
    returning id into nid;
    return jsonb_build_object('ok',true,'plan',nid,'state','مسودّة',
      'note','حُفظت الخطّةُ مسودّةً — استشر معلّمَ الفصل ووليَّ الأمر ثمّ اعتمدها');
  end if;

  select * into cur from v2.behavior_plans where id=p_plan;
  if cur.id is null then raise exception 'الخطّةُ غيرُ موجودة'; end if;
  if not v2.my_school(coalesce(cur.school_id,sc)) then raise exception 'ليست مدرستك'; end if;
  if cur.status in ('final','closed') then
    raise exception 'اعتُمدت هذي الخطّةُ — فلا تُعدَّل. وإن تغيّر الحالُ فاكتب خطّةً جديدة'; end if;

  update v2.behavior_plans set
    problem_desc=btrim(p_desc), target_behavior=btrim(p_target), steps=string_to_array(btrim(p_steps),E'\n'),
    manifestations=nullif(btrim(coalesce(p_manifest,'')),''),
    antecedents=nullif(btrim(coalesce(p_ante,'')),''),
    consequences=nullif(btrim(coalesce(p_conseq,'')),''),
    student_gain=nullif(btrim(coalesce(p_gain,'')),''),
    prior_actions=nullif(btrim(coalesce(p_prior,'')),''),
    starts_on=coalesce(p_starts,starts_on), ends_on=coalesce(p_ends,ends_on)
   where id=p_plan;
  return jsonb_build_object('ok',true,'plan',p_plan,'note','عُدّلت الخطّة');
end $function$
;
