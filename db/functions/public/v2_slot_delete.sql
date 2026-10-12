-- public.v2_slot_delete(p_slot uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b04870fb3a03fdeec91ca840e672bca5
CREATE OR REPLACE FUNCTION public.v2_slot_delete(p_slot uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t record;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'حذفَ حصّةٍ من الجدول');
  select * into t from v2.timetable where id=p_slot;
  if t.id is null then raise exception 'الحصّةُ غيرُ موجودة'; end if;
  if not v2.my_school(t.school_id) then raise exception '%', v2.not_my_school_ar(); end if;
  if btrim(coalesce(p_reason,''))='' then
    raise exception 'لا تُحذف حصّةٌ بلا سببٍ مكتوب'; end if;
  delete from v2.timetable where id=p_slot;
  return jsonb_build_object('ok',true);
end $function$
;
