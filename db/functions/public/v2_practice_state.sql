-- public.v2_practice_state(p_school uuid, p_code text, p_state text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0be6ced4f85d44163c6ff55cd0853d14
CREATE OR REPLACE FUNCTION public.v2_practice_state(p_school uuid, p_code text, p_state text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبط ممارسات الصفّ');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_state not in ('أخفِ','أظهِر','أعدها للأصل') then
    raise exception 'الحال: «أخفِ» أو «أظهِر» أو «أعدها للأصل»'; end if;
  select * into cur from v2.class_practices where code=p_code;
  if cur.code is null then raise exception 'ممارسةٌ غيرُ موجودة'; end if;
  if cur.school_id is not null and cur.school_id <> p_school then
    raise exception 'هذي الممارسةُ لمدرسةٍ أخرى'; end if;

  -- ممارسةُ المدرسة نفسِها
  if cur.school_id = p_school then
    if p_state = 'أعدها للأصل' then
      raise exception 'هذي ممارسةٌ أنشأتها مدرستُك — ولا أصلَ مشتركَ لها. أخفِها إن شئت'; end if;
    update v2.class_practices set active = (p_state='أظهِر') where code=p_code;
    return jsonb_build_object('ok',true,'code',p_code,'state',p_state);
  end if;

  -- مشتركة
  if p_state = 'أعدها للأصل' then
    delete from v2.practice_overrides where school_id=p_school and code=p_code;
    return jsonb_build_object('ok',true,'code',p_code,'state','رجعت للمشترك');
  end if;

  insert into v2.practice_overrides(school_id,code,hidden,set_by)
  values (p_school,p_code,(p_state='أخفِ'),v2.current_person())
  on conflict (school_id,code) do update set
    hidden=(p_state='أخفِ'), set_by=excluded.set_by, set_at=now();
  return jsonb_build_object('ok',true,'code',p_code,'state',p_state);
end $function$
;
