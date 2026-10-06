-- public.v2_staff_list(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 eb8882590f88b90b8232c781f2e7ee48
CREATE OR REPLACE FUNCTION public.v2_staff_list(p_school uuid)
 RETURNS TABLE(person_id uuid, name_ar text, post_ar text, roles_ar text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة المنسوبين');
  return query
   select distinct pe.id, v2.fn_display_name(pe.full_name), v2.role_ar(pe.post_key),
    (select string_agg(distinct ps.label_ar,' · ') from v2.assignments a2
      join v2.posts ps on ps.key=a2.post_key
      where a2.person_id=pe.id and a2.school_id=p_school and a2.ended_on is null)
   from v2.people pe join v2.assignments a on a.person_id=pe.id
   where a.school_id=p_school and a.ended_on is null and pe.status='active'
   order by 2;
end $function$
;
