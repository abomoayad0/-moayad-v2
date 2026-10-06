-- public.v2_absence_task_delegate(p_task uuid, p_person uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8d3433cc38cf74b4160701f250f99289
CREATE OR REPLACE FUNCTION public.v2_absence_task_delegate(p_task uuid, p_person uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st uuid; sc uuid; nm text; m text; d text; h text; c text; sqs text;
begin
  if btrim(coalesce(p_note,''))='' then raise exception 'لا يُحوَّل تكليف بلا سبب مكتوب'; end if;
  select c2.student_id into st from v2.absence_tasks t join v2.absence_cases c2 on c2.id=t.case_id
   where t.id=p_task;
  if st is null then raise exception 'المهمة غير موجودة'; end if;
  perform v2.assert_my_student(st,'تحويل مهمّة غياب');
  perform v2.assert_role(array['deputy_students','deputy','principal'],'تحويل مهامّ الغياب');
  select e.school_id into sc from v2.enrolments e where e.student_id=st and e.status='active' limit 1;
  if not exists (select 1 from v2.assignments a where a.person_id=p_person and a.school_id=sc and a.ended_on is null) then
    raise exception 'هذا المنسوب ليس من منسوبي المدرسة'; end if;
  select v2.fn_display_name(full_name) into nm from v2.people where id=p_person;
  update v2.absence_tasks set owner_person=p_person, delegated_by=v2.current_person(),
    delegated_at=now(), delegate_note=p_note where id=p_task and status='open';
  if not found then raise exception 'المهمة ليست مفتوحة'; end if;
  return jsonb_build_object('ok',true,'to',nm,'note',p_note);
exception when others then
  get stacked diagnostics sqs=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_absence_task_delegate','المواظبة','تحويل مهمّة',
    jsonb_build_object('task',p_task,'to',p_person),sqs,d,h,c,'bridge',
    case when sqs='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = sqs;
end $function$
;
