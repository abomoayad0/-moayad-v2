-- v2.my_owner_roles(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 fa9c32389ef8c226195f229622bcf1a9
CREATE OR REPLACE FUNCTION v2.my_owner_roles(p_school uuid)
 RETURNS text[]
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(array_agg(m.owner_role), '{}'::text[])
  from v2.task_role_map m
  where not m.is_external
    and (
      (m.role_keys && v2.my_post_keys())
      or (m.committee_key is not null and exists (
            select 1 from v2.committee_members cm
             where cm.committee_key = m.committee_key
               and cm.person_id = v2.current_person()
               and cm.school_id = p_school
               and (cm.ended_on is null or cm.ended_on >= current_date)
               and (cm.year_id is null or cm.year_id in
                     (select y.id from v2.academic_years y
                       where y.school_id = p_school and y.is_current))))
    );
$function$
;
