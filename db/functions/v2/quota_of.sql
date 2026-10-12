-- v2.quota_of(p_school uuid, p_person uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 049a807d45ea0ee87cbd437fd6dac4b8
CREATE OR REPLACE FUNCTION v2.quota_of(p_school uuid, p_person uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(
    (select max(q.max_slots) from v2.teaching_quota q
       join v2.assignments a on a.post_key = q.post_key
      where q.school_id = p_school and a.person_id = p_person
        and a.school_id = p_school and a.ended_on is null),
    v2.teacher_quota(p_school, p_person))::int;
$function$
;
