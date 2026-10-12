-- public.v2_student_roles()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 28170ad9c1fe1f0ff41eb98df5b8da49
CREATE OR REPLACE FUNCTION public.v2_student_roles()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_st uuid;
begin
  select s.id into v_st from v2.students s
   where s.user_id = auth.uid() and coalesce(s.portal_active,false);
  if v_st is null then raise exception 'بوّابتُك غيرُ مفتوحة'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'role_ar',h.role_ar,'subject',h.subject_ar,
        'until_ar', v2.fn_to_hijri(h.until_on),
        'days_left',(h.until_on - current_date),
        'by_ar',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=h.by_person))
      order by h.subject_ar)
    from v2.class_role_holders h
    where h.student_id=v_st and h.ended_at is null
      and (h.until_on is null or h.until_on >= current_date)), '[]'::jsonb);
end $function$
;
