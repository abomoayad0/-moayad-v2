-- public.v2_resume_escalation(p_case uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 96b79646e3c78ea128ca454edd97051c
CREATE OR REPLACE FUNCTION public.v2_resume_escalation(p_case uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record;
begin
  perform v2.assert_role(array['principal'],'رفعَ وقفِ التصعيد');
  select * into c from v2.absence_cases where id=p_case;
  if c.id is null then raise exception 'الحالةُ غيرُ موجودة'; end if;
  perform v2.assert_my_school(c.school_id,'رفعَ وقفِ التصعيد');
  if not coalesce(c.escalation_halted,false) then
    raise exception 'تصعيدُ هذي الحالة غيرُ موقوف'; end if;
  if length(btrim(coalesce(p_reason,''))) < 10 then
    raise exception 'رفعُ الوقف لا يقع بلا سببٍ مكتوب'; end if;

  update v2.absence_cases
     set escalation_halted = false,
         halt_reason = coalesce(halt_reason,'')||' ⟂ رُفع الوقفُ '||
                       coalesce(v2.fn_to_hijri(current_date)||' هـ','')||': '||btrim(p_reason)
   where id = p_case;

  perform v2.log_action(c.school_id,c.student_id,'resume_escalation','رُفع وقفُ التصعيد',
    'absence_cases',p_case, jsonb_build_object('reason',btrim(p_reason)));

  return jsonb_build_object('ok',true,'case',p_case,'halted',false,
    'note_ar','رُفع الوقفُ — والسببُ الأوّلُ وسببُ الرفع كلاهما باقيان في السجلّ لا يُمحى أحدُهما');
end $function$
;
