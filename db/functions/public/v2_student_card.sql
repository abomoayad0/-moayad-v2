-- public.v2_student_card(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e88bf68c6a35907aff5038643530a486
CREATE OR REPLACE FUNCTION public.v2_student_card(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_student(p_student,'قراءة بطاقة الطالب');
  return v2.fn_student_card(p_student);
end $function$
;
