-- public.v2_census_assign(p_student uuid, p_task uuid, p_person uuid, p_days smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4342e7f7fccd48a9e7a551bde28a80f2
CREATE OR REPLACE FUNCTION public.v2_census_assign(p_student uuid, p_task uuid, p_person uuid, p_days smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; rid uuid; nid uuid; t record; nm text;
begin
  perform v2.assert_role(array['deputy_students','deputy','principal'],
      'التكليفَ بحصر السلوكيّات');
  perform v2.assert_my_student(p_student,'حصر السلوكيات');
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;

  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_person and a.school_id=sc and a.ended_on is null) then
    raise exception 'المكلَّفُ ليس من منسوبي مدرستك'; end if;
  if coalesce(p_days,5) < 1 or coalesce(p_days,5) > 30 then
    raise exception 'مدّةُ الحصر من يومٍ إلى ثلاثين'; end if;

  if p_task is not null then
    select * into t from v2.behavior_tasks where id=p_task;
    if t.id is null then raise exception 'المهمّةُ غيرُ موجودة'; end if;
    if t.kind <> 'follow_up' then
      raise exception 'هذي ليست مهمّةَ حصر السلوكيّات'; end if;
    rid := t.record_id;
  end if;

  if exists (select 1 from v2.behavior_census c
              where c.student_id=p_student and c.state='مكلَّف'
                and coalesce(c.task_id,'00000000-0000-0000-0000-000000000000'::uuid)
                  = coalesce(p_task,'00000000-0000-0000-0000-000000000000'::uuid)) then
    raise exception 'ثمّة تكليفُ حصرٍ قائمٌ لم يُسلَّم بعد'; end if;

  insert into v2.behavior_census(school_id,student_id,task_id,record_id,
      assigned_to,assigned_by,days,due_on,is_test)
  values (sc,p_student,p_task,rid,p_person,v2.current_person(),
      coalesce(p_days,5), current_date + coalesce(p_days,5),
      coalesce((select test_mode from v2.schools where id=sc),false))
  returning id into nid;

  select v2.fn_display_name(full_name) into nm from v2.people where id=p_person;
  return jsonb_build_object('ok',true,'census',nid,'to',nm,
    'due', current_date + coalesce(p_days,5),
    'note','كُلّف '||nm||' بحصر سلوكيّات الطالب '||v2.ar_num(coalesce(p_days,5))||' أيّام');
end $function$
;
