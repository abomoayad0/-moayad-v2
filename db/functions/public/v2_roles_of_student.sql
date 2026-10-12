-- public.v2_roles_of_student(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7860ed0cd046952579bc98b7233fccdf
CREATE OR REPLACE FUNCTION public.v2_roles_of_student(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_student(p_student,'أدوارَ الطالب');
  return coalesce((
    select jsonb_agg(jsonb_build_object(
        'holder',h.id,'role_ar',h.role_ar,'subject',h.subject_ar,
        'until_ar', v2.fn_to_hijri(h.until_on),
        'days_left',(h.until_on - current_date),
        'mine', h.by_person = v2.current_person(),
        'by_ar',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=h.by_person))
      order by h.subject_ar)
    from v2.class_role_holders h
    where h.student_id=p_student and h.ended_at is null
      and (h.until_on is null or h.until_on >= current_date)), '[]'::jsonb);
end $function$
;
