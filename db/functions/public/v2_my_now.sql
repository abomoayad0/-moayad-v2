-- public.v2_my_now(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 821c38b2fe94f59733dc2b827452d687
CREATE OR REPLACE FUNCTION public.v2_my_now(p_school uuid)
 RETURNS TABLE(period_no smallint, starts_at time without time zone, ends_at time without time zone, section_label text, subject_ar text, room_ar text, students_n integer, section_id uuid, state text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة جدولي');
  return query select * from v2.fn_my_now(p_school);
end $function$
;
