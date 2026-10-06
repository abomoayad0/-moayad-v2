-- public.v2_guardians_of(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d46bbd6a98c530425d778e0454065d91
CREATE OR REPLACE FUNCTION public.v2_guardians_of(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_student(p_student,'كشف أولياء الأمر');
  select coalesce(jsonb_agg(jsonb_build_object(
      'guardian',g.id,'name',g.full_name,'relation',g.relation,
      'national_id',g.national_id,'phone',g.phone,
      'work_phone',g.work_phone,'home_phone',g.home_phone,'other_phone',g.other_phone,
      'workplace',g.workplace_ar,'is_primary',g.is_primary,
      'portal',g.portal_active,'has_account',(g.user_id is not null))
      order by g.is_primary desc, g.full_name),'[]'::jsonb)
  into r from v2.guardians g where g.student_id=p_student;
  return r;
end $function$
;
