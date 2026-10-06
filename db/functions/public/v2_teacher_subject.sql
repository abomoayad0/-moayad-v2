-- public.v2_teacher_subject(p_school uuid, p_person uuid, p_subject text, p_main boolean, p_remove boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1c94ff47f17bf41a1062278b57cdff9a
CREATE OR REPLACE FUNCTION public.v2_teacher_subject(p_school uuid, p_person uuid, p_subject text, p_main boolean, p_remove boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy'],'ضبطَ تخصّص المعلّم');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if not exists (select 1 from v2.assignments a
        where a.person_id=p_person and a.school_id=p_school and a.ended_on is null) then
    raise exception 'هذا المنسوب ليس من منسوبي مدرستك'; end if;
  if btrim(coalesce(p_subject,''))='' then raise exception 'اكتب اسمَ المادّة'; end if;

  if coalesce(p_remove,false) then
    delete from v2.teacher_subjects
     where school_id=p_school and person_id=p_person and subject_ar=btrim(p_subject);
    return jsonb_build_object('ok',true,'mode','حُذفت');
  end if;
  insert into v2.teacher_subjects(school_id,person_id,subject_ar,is_main)
  values (p_school,p_person,btrim(p_subject),coalesce(p_main,true))
  on conflict (school_id,person_id,subject_ar) do update set is_main=excluded.is_main;
  return jsonb_build_object('ok',true,'mode','أُضيفت');
end $function$
;
