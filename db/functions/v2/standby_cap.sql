-- v2.standby_cap(p_school uuid, p_person uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d50873a47f84bf61491091ac0843c1b0
CREATE OR REPLACE FUNCTION v2.standby_cap(p_school uuid, p_person uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(
    (select max(q.standby_max) from v2.teaching_quota q
       join v2.assignments a on a.post_key = q.post_key
      where q.school_id = p_school and a.person_id = p_person
        and a.school_id = p_school and a.ended_on is null), 99)::int;
$function$
;
