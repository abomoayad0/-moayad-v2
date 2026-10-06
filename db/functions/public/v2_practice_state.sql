-- public.v2_practice_state(p_school uuid, p_code text, p_state text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 32d6e09b8d81dc8b2d23863e0ee9f9c3
CREATE OR REPLACE FUNCTION public.v2_practice_state(p_school uuid, p_code text, p_state text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record; o record; empty boolean;
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

  if p_state = 'أعدها للأصل' then
    if cur.school_id = p_school then
      raise exception 'هذي ممارسةٌ أنشأتها مدرستُك — ولا أصلَ مشتركَ لها. أخفِها إن شئت'; end if;
    delete from v2.practice_overrides where school_id=p_school and code=p_code;
    return jsonb_build_object('ok',true,'code',p_code,'state','رجعت للمشترك');
  end if;

  -- 🔑 الإخفاءُ والإظهارُ يُقيَّدان في سطر التعديل للاثنين
  --    فما أنشأته المدرسةُ وأخفته يُقرأ في المخفيّ ويُظهَر
  insert into v2.practice_overrides(school_id,code,hidden,set_by)
  values (p_school,p_code,(p_state='أخفِ'),v2.current_person())
  on conflict (school_id,code) do update set
    hidden=(p_state='أخفِ'), set_by=excluded.set_by, set_at=now();

  -- 🔑 وإن صار السطرُ فارغًا بعد الإظهار فلا يُترك، فلا تُوسم «معدَّلة» وهي لم تُعدَّل
  if p_state='أظهِر' then
    select * into o from v2.practice_overrides where school_id=p_school and code=p_code;
    empty := (o.title_ar is null and o.points is null and o.polarity is null
      and o.scope is null and o.kind is null and o.zone is null
      and o.once_per_day is null and o.threshold_count is null and o.threshold_days is null
      and o.escalate_to is null and o.escalate_note is null and o.note_ar is null
      and o.ord is null);
    if empty then
      delete from v2.practice_overrides where school_id=p_school and code=p_code; end if;
  end if;

  return jsonb_build_object('ok',true,'code',p_code,'state',p_state);
end $function$
;
