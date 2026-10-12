-- public.v2_session_lesson(p_session uuid, p_item uuid, p_text text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8cb4aacf39338225d4e20cf6f35552a3
CREATE OR REPLACE FUNCTION public.v2_session_lesson(p_session uuid, p_item uuid DEFAULT NULL::uuid, p_text text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare s record; v_t text;
begin
  select * into s from v2.class_sessions where id=p_session;
  if s.id is null then raise exception 'جلسةٌ غيرُ موجودة'; end if;
  if not v2.my_school(s.school_id) then raise exception 'ليست مدرستَك'; end if;
  if s.person_id <> v2.current_person() then raise exception 'ليست حصّتَك'; end if;
  if p_item is null and btrim(coalesce(p_text,''))='' then
    raise exception 'اختر الدرسَ من التوزيع أو اكتبه'; end if;

  v_t := nullif(btrim(coalesce(p_text,'')),'');
  if p_item is not null and v_t is null then
    select coalesce(cl.title_ar, 'درسٌ من التوزيع') into v_t
      from v2.lesson_plan_items li
      left join v2.curriculum_lessons cl on cl.id = li.lesson_id
     where li.id = p_item;
  end if;

  update v2.class_sessions set lesson_item=p_item, lesson_ar=v_t where id=p_session;
  return jsonb_build_object('ok',true,'lesson_ar',v_t,
    'msg','درسُ الحصّة: '||v_t||
      case when p_item is null then ' · خارجَ التوزيع' else ' · من توزيع المنهج' end);
end $function$
;
