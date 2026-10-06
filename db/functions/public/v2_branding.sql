-- public.v2_branding(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ca958bb8b52b522f256f00a9b3bd43e6
CREATE OR REPLACE FUNCTION public.v2_branding(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة الهوية البصرية');
  return (select to_jsonb(b) || jsonb_build_object('school', s.name_ar)
          from v2.branding b join v2.schools s on s.id=b.school_id where b.school_id=p_school);
end $function$
;
