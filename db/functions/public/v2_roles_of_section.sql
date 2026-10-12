-- public.v2_roles_of_section(p_section uuid, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ef8ee6bf8fadf1f2985da5102a5d2317
CREATE OR REPLACE FUNCTION public.v2_roles_of_section(p_section uuid, p_subject text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  select school_id into sc from v2.class_sections where id=p_section;
  if sc is null then raise exception 'فصلٌ غيرُ موجود'; end if;
  if not v2.my_school(sc) then raise exception 'ليست مدرستَك'; end if;

  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'holder',h.id,'role_code',h.role_code,'role_ar',h.role_ar,
        'student',h.student_id,
        'student_ar',(select v2.fn_display_name(s.full_name) from v2.students s where s.id=h.student_id),
        'subject',h.subject_ar,
        'until_ar', v2.fn_to_hijri(h.until_on),
        'days_left', (h.until_on - current_date),
        'mine', h.by_person = v2.current_person())
      order by h.role_ar, h.from_on)
    from v2.class_role_holders h
    where h.section_id=p_section and h.ended_at is null
      and (h.until_on is null or h.until_on >= current_date)
      and (p_subject is null or h.subject_ar = p_subject)), '[]'::jsonb);
end $function$
;
