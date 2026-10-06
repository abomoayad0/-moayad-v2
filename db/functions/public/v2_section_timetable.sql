-- public.v2_section_timetable(p_section uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1f9c2829045658a13beb318b1534f277
CREATE OR REPLACE FUNCTION public.v2_section_timetable(p_section uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS TABLE(weekday smallint, weekday_ar text, period_no smallint, starts_at time without time zone, ends_at time without time zone, subject_ar text, teacher text, room_ar text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  select school_id into sc from v2.class_sections where id=p_section;
  perform v2.assert_my_school(sc,'قراءة جدول الفصل');
  return query select * from v2.fn_section_timetable(p_section,p_term);
end $function$
;
