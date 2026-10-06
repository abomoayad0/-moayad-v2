-- public.v2_record_practice(p_student uuid, p_code text, p_period smallint, p_subject text, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 651d9842027d9a3cb0557e65211a67df
CREATE OR REPLACE FUNCTION public.v2_record_practice(p_student uuid, p_code text, p_period smallint DEFAULT NULL::smallint, p_subject text DEFAULT NULL::text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_student(p_student,'رصد ممارسة صفّية');
  return v2.fn_record_practice(p_student,p_code,p_period,p_subject,p_note,v2.current_person());
end $function$
;
