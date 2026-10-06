-- public.v2_task_skip(p_task uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5a4093634bbe75519b7207e2ccc74714
CREATE OR REPLACE FUNCTION public.v2_task_skip(p_task uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st uuid;
begin
  if btrim(coalesce(p_reason,''))='' then raise exception 'لا تسقط مهمة بلا سبب مكتوب'; end if;
  select r.student_id into st from v2.behavior_tasks t join v2.behavior_records r on r.id=t.record_id
   where t.id=p_task;
  if st is null then raise exception 'المهمة غير موجودة'; end if;
  perform v2.assert_my_student(st,'إسقاط مهمّة سلوكية');
  perform v2.assert_role(array['counselor','deputy_students','admin_assistant','principal'],
    'إسقاط مهامّ المشكلات السلوكية');
  update v2.behavior_tasks set status='skipped', skip_reason=p_reason,
    done_at=now(), done_by=v2.current_person() where id=p_task and status='open';
end $function$
;
