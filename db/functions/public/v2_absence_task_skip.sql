-- public.v2_absence_task_skip(p_task uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 aa642ce1898a6886a6c4a1641a2534c7
CREATE OR REPLACE FUNCTION public.v2_absence_task_skip(p_task uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st uuid;
begin
  if btrim(coalesce(p_reason,''))='' then raise exception 'لا تسقط مهمة بلا سبب مكتوب'; end if;
  select c.student_id into st from v2.absence_tasks t join v2.absence_cases c on c.id=t.case_id
   where t.id=p_task;
  if st is null then raise exception 'المهمة غير موجودة'; end if;
  perform v2.assert_my_student(st,'إسقاط مهمّة غياب');
  perform v2.assert_role(array['counselor','deputy_students','admin_assistant','principal'],
    'إسقاط مهامّ الغياب');
  update v2.absence_tasks set status='skipped', skip_reason=p_reason,
    done_at=now(), done_by=v2.current_person() where id=p_task and status='open';
end $function$
;
