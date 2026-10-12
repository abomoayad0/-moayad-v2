-- public.v2_session_attendance(p_session uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bb3ed3e58bc30b3580e963cf780b4678
CREATE OR REPLACE FUNCTION public.v2_session_attendance(p_session uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare s record;
begin
  select * into s from v2.class_sessions where id=p_session;
  if s.id is null then raise exception 'جلسةٌ غيرُ موجودة'; end if;
  if not v2.my_school(s.school_id) then raise exception 'ليست مدرستَك'; end if;
  if s.person_id <> v2.current_person() then raise exception 'ليست حصّتَك'; end if;
  if s.attendance_at is not null then raise exception 'اعتُمد حضورُها من قبل'; end if;
  update v2.class_sessions set attendance_at=now(), attendance_by=v2.current_person()
   where id=p_session;
  return jsonb_build_object('ok',true,'msg','اعتُمد حضورُ الحصّة — ولا يُعدَّل بعده إلّا من القيادة');
end $function$
;
