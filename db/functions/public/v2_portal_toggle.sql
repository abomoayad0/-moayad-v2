-- public.v2_portal_toggle(p_kind text, p_id uuid, p_open boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2cf922466259bf3208c95a8783963e49
CREATE OR REPLACE FUNCTION public.v2_portal_toggle(p_kind text, p_id uuid, p_open boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sid uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'فتحَ البوّابة أو إغلاقَها');
  if p_kind not in ('guardian','student') then
    raise exception 'البوّابة: «وليّ أمر» أو «طالب»'; end if;

  if p_kind='guardian' then
    select student_id into sid from v2.guardians where id=p_id;
    if sid is null then raise exception 'وليُّ أمرٍ غيرُ موجود'; end if;
    perform v2.assert_my_student(sid,'بوّابة وليّ الأمر');
    update v2.guardians set portal_active=coalesce(p_open,false) where id=p_id;
    return jsonb_build_object('ok',true,'portal',coalesce(p_open,false));
  end if;

  -- 🔴 بوّابةُ الطالب — قاصرٌ، فتُفتح بقرارٍ لا بزرّ
  perform v2.assert_my_student(p_id,'بوّابة الطالب');
  if coalesce(p_open,false) and not exists (
       select 1 from v2.students where id=p_id and user_id is not null) then
    raise exception 'لا حسابَ لهذا الطالب بعد — ولا تُفتح بوّابةٌ بلا حساب'; end if;
  update v2.students set portal_active=coalesce(p_open,false) where id=p_id;
  return jsonb_build_object('ok',true,'portal',coalesce(p_open,false));
end $function$
;
