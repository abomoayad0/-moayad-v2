-- public.v2_move_class_targets(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e5e09ec28464d3e906876d94c6ee846f
CREATE OR REPLACE FUNCTION public.v2_move_class_targets(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r record;
begin
  select br.student_id sid into r from v2.behavior_records br where br.id = p_record;
  if r.sid is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(r.sid, 'فصولُ النقل المتاحة');
  return v2.fn_move_blocks(p_record);
end
$function$
;
