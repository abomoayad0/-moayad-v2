-- public.v2_session_close(p_session uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ea4e434d110ebd9cdd20a342e3be3a93
CREATE OR REPLACE FUNCTION public.v2_session_close(p_session uuid, p_note text DEFAULT NULL::text)
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
  if s.closed_at is not null then raise exception 'أُقفلت من قبل'; end if;
  if v2.rule_n(s.school_id,'session_needs_attendance')=1 and s.attendance_at is null then
    raise exception 'لا تُقفل الحصّةُ قبل اعتماد حضورها'; end if;
  if v2.rule_n(s.school_id,'session_needs_lesson')=1 and s.lesson_ar is null then
    raise exception 'لا تُقفل الحصّةُ بلا درس — فبه يُعرف أين وصل المنهج'; end if;

  update v2.class_sessions
     set closed_at=now(), closed_by=v2.current_person(),
         note_ar=nullif(btrim(coalesce(p_note,'')),'')
   where id=p_session;
  return jsonb_build_object('ok',true,'msg','أُقفلت الحصّةُ — ومُثبتٌ فيها الحضورُ والدرس');
end $function$
;
