-- public.v2_assign_end(p_assignment uuid, p_ended_on date, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0f4f086df4e7788eccaabc2127640ee7
CREATE OR REPLACE FUNCTION public.v2_assign_end(p_assignment uuid, p_ended_on date, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare a record;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'إنهاء تكليف');
  select * into a from v2.assignments where id=p_assignment;
  if a.id is null then raise exception 'التكليفُ غيرُ موجود'; end if;
  if not v2.my_school(a.school_id) then raise exception 'ليست مدرستك'; end if;
  if a.ended_on is not null then
    raise exception 'انتهى هذا التكليفُ سلفًا بتاريخ %', a.ended_on; end if;
  if p_reason not in ('transferred','resigned','assignment_ended','deceased','leave',
                      'year_closed','other') then
    raise exception 'سببُ الإنهاء غيرُ معروف'; end if;
  update v2.assignments set ended_on=coalesce(p_ended_on,current_date), end_reason=p_reason
   where id=p_assignment;
  return jsonb_build_object('ok',true);
end $function$
;
