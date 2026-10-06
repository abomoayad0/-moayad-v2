-- v2.acting_posts(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 962fcf20c5a193ca6ae31406ca11ee9d
CREATE OR REPLACE FUNCTION v2.acting_posts(p_school uuid)
 RETURNS TABLE(post_key text, by_delegation boolean, delegation_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select a.post_key, false, null::uuid
    from v2.assignments a
   where a.person_id = v2.current_person() and a.school_id = p_school
     and a.ended_on is null
  union
  select d.post_key, true, d.id
    from v2.delegations d
   where d.to_person = v2.current_person() and d.school_id = p_school
     and d.revoked_at is null
     and d.starts_on <= current_date
     and (d.ends_on is null or d.ends_on >= current_date);
$function$
;
