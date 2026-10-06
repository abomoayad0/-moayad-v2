-- public.v2_undo_practice(p_record uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cd2c3e16a72c4dadab10aa580361af1e
CREATE OR REPLACE FUNCTION public.v2_undo_practice(p_record uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st uuid;
begin
  select student_id into st from v2.practice_records where id=p_record;
  perform v2.assert_my_student(st,'إلغاء ممارسة');
  perform v2.fn_undo_practice(p_record,p_reason);
end $function$
;
