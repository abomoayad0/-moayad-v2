-- public.v2_plan_opinion(p_plan uuid, p_who text, p_text text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e138d0445a280cdd3624a2ed36303f8a
CREATE OR REPLACE FUNCTION public.v2_plan_opinion(p_plan uuid, p_who text, p_text text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record; who text;
begin
  select * into cur from v2.behavior_plans where id=p_plan;
  if cur.id is null then raise exception 'الخطّةُ غيرُ موجودة'; end if;
  if cur.status in ('final','closed') then
    raise exception 'اعتُمدت الخطّةُ — فلا يُضاف إليها رأي'; end if;
  if btrim(coalesce(p_text,''))='' then raise exception 'اكتب رأيَك'; end if;

  if p_who = 'guardian' then
    -- 🔒 رأيُ وليّ الأمر يكتبه هو
    who := v2.caller_kind(cur.student_id);
    if who <> 'guardian' then
      raise exception 'رأيُ وليّ الأمر يكتبه هو من بوّابته — ولا تملؤه المدرسة'; end if;
    update v2.behavior_plans set guardian_opinion=btrim(p_text), guardian_at=now()
     where id=p_plan;
  elsif p_who = 'teacher' then
    perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher',
        'counselor','deputy_students','deputy','principal'],'إبداءَ رأي معلّم الفصل');
    update v2.behavior_plans set teacher_opinion=btrim(p_text),
        teacher_by=v2.current_person(), teacher_at=now() where id=p_plan;
  elsif p_who = 'deputy' then
    perform v2.assert_role(array['deputy_students','deputy','principal'],'رأيَ الوكيل');
    update v2.behavior_plans set deputy_opinion=btrim(p_text) where id=p_plan;
  else
    raise exception 'الرأي: معلّمُ الفصل · وليُّ الأمر · الوكيل';
  end if;
  return jsonb_build_object('ok',true);
end $function$
;
