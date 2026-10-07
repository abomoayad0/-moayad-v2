-- public.v2_census_self(p_student uuid, p_task uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_limit text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2b9f9f4c76f200cecd8d63c0714f7be9
CREATE OR REPLACE FUNCTION public.v2_census_self(p_student uuid, p_task uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_limit text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; rid uuid; nid uuid; t record; closed boolean := false; n int;
begin
  perform v2.assert_role(array['deputy_students','deputy','principal',
      'subject_teacher','sped_teacher','gifted_teacher','counselor'],'حصرَ السلوكيّات');
  perform v2.assert_my_student(p_student,'حصر السلوكيات');
  if p_neg is null or array_length(p_neg,1) is null then
    raise exception 'اختر سلوكًا سلبيًّا واحدًا على الأقلّ'; end if;
  if btrim(coalesce(p_causes,''))='' then
    raise exception 'اكتب مسبّبات السلوك — فالدليلُ يوجب حصرَها'; end if;

  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;

  -- تحقّقٌ أنّ ما اختير من قوائم مدرستك
  select count(*) into n from unnest(p_neg || coalesce(p_pos,'{}'::uuid[])) x
   where not exists (select 1 from v2.census_items c
      where c.id=x and c.active and (c.school_id is null or c.school_id=sc));
  if n > 0 then raise exception 'فيما اخترتَ ما ليس من قوائم مدرستك'; end if;

  if p_task is not null then
    select * into t from v2.behavior_tasks where id=p_task;
    if t.id is null then raise exception 'المهمّةُ غيرُ موجودة'; end if;
    if t.kind <> 'follow_up' then raise exception 'هذي ليست مهمّةَ حصر السلوكيّات'; end if;
    rid := t.record_id;
  end if;

  insert into v2.behavior_census(school_id,student_id,task_id,record_id,
      assigned_to,assigned_by,days,due_on,state,by_self,
      neg_items,pos_items,causes,suggestion,
      positives,negatives,filed_at,is_test)
  values (sc,p_student,p_task,rid,v2.current_person(),v2.current_person(),0,current_date,
      'مكتمل',true,p_neg,p_pos,btrim(p_causes),
      nullif(btrim(coalesce(p_limit,'')),''),
      (select string_agg(c.icon||' '||c.text_ar,' · ') from v2.census_items c
        where c.id = any(coalesce(p_pos,'{}'::uuid[]))),
      (select string_agg(c.icon||' '||c.text_ar,' · ') from v2.census_items c
        where c.id = any(p_neg)),
      now(), coalesce((select test_mode from v2.schools where id=sc),false))
  returning id into nid;

  if p_task is not null then
    update v2.behavior_tasks set status='done', done_at=now(), done_by=v2.current_person(),
        ev_on=current_date,
        ev_text='حصرَها '||coalesce(v2.role_ar(v2.my_role()),'المنسوب')||' بنفسه — '||
                v2.ar_num(array_length(p_neg,1))||' سلبيّةً · '||
                v2.ar_num(coalesce(array_length(p_pos,1),0))||' إيجابيّة'
     where id=p_task and status<>'done';
    closed := found;
  end if;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (sc,'census',current_date,p_student,'حُصرت السلوكيّات',
      v2.ar_num(array_length(p_neg,1))||' سلبيّةً · '||
      v2.ar_num(coalesce(array_length(p_pos,1),0))||' إيجابيّة',
      'behavior_census',nid,'staff',
      coalesce((select test_mode from v2.schools where id=sc),false));

  return jsonb_build_object('ok',true,'census',nid,'closed',closed,
    'neg',array_length(p_neg,1),'pos',coalesce(array_length(p_pos,1),0),
    'note', case when closed then 'حُفظ الحصرُ وأُقفلت المهمّة' else 'حُفظ الحصر' end);
end $function$
;
