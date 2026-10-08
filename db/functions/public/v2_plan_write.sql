-- public.v2_plan_write(p_student uuid, p_record uuid, p_task uuid, p_plan uuid, p_desc text, p_manifest text, p_ante text, p_conseq text, p_gain text, p_prior text, p_target text, p_steps text, p_starts date, p_ends date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 875e50ffdea8e87c7be18c768dfdfd2b
CREATE OR REPLACE FUNCTION public.v2_plan_write(p_student uuid, p_record uuid, p_task uuid, p_plan uuid, p_desc text, p_manifest text, p_ante text, p_conseq text, p_gain text, p_prior text, p_target text, p_steps text, p_starts date, p_ends date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; sc uuid; cur record; prev record;
        v_new text[]; v_prob integer;
begin
  perform v2.assert_role(array['counselor','deputy_students','deputy','principal'],
                         'كتابةَ خطّة تعديل السلوك');
  perform v2.assert_my_student(p_student,'خطة تعديل السلوك');
  if btrim(coalesce(p_desc,''))='' then raise exception 'صِف السلوكَ المراد تعديلُه'; end if;
  if btrim(coalesce(p_target,''))='' then raise exception 'اكتب السلوكَ البديلَ المستهدف'; end if;
  if btrim(coalesce(p_steps,''))='' then raise exception 'اكتب إجراءاتِ التعديل'; end if;

  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;

  -- 🔑 الحارسُ: الخطّةُ التالية تُغيَّر ولا تُنسَخ
  if p_record is not null then
    select r.problem_id into v_prob from v2.behavior_records r where r.id=p_record;

    select bp.id, bp.steps, bp.final_at, bp.target_behavior into prev
      from v2.behavior_plans bp
      join v2.behavior_records br on br.id = bp.record_id
     where bp.student_id = p_student
       and br.problem_id = v_prob
       and bp.status = 'final'
       and (p_plan is null or bp.id <> p_plan)
     order by bp.final_at desc nulls last
     limit 1;

    if prev.id is not null then
      select array_agg(btrim(x) order by btrim(x))
        into v_new
        from unnest(string_to_array(btrim(p_steps), E'\n')) x
       where btrim(x) <> '';

      if v_new is not null
         and v_new = (select array_agg(btrim(y) order by btrim(y))
                        from unnest(prev.steps) y where btrim(y) <> '') then
        raise exception
          'إجراءُ هذي الخطوة يقوم على تغيير خطّة تعديل السلوك — وهذي نسخةٌ من الخطّة المعتمدة في %: لم تتغيّر إجراءاتُ التعديل · وللسلوكِ المستهدف أن يبقى كما هو (فالمشكلةُ لم تتغيّر)، والذي يجب أن يتغيّر هو الطريقُ إليه',
          coalesce(to_char(prev.final_at,'YYYY-MM-DD'),'خطّةٍ سابقة');
      end if;
    end if;
  end if;

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
end
$function$
;
