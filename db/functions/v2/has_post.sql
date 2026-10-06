-- v2.has_post(p_posts text[])
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a9d732fb03db7b1a0dbbd60d535f7ab4
CREATE OR REPLACE FUNCTION v2.has_post(p_posts text[])
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select exists (
    select 1 from v2.assignments a
     where a.person_id = v2.current_person() and a.ended_on is null
       and a.post_key = any(p_posts)
       and (v2.acting_school() is null or a.school_id = v2.acting_school()))
  or exists (
    select 1 from v2.delegations d
     where d.to_person = v2.current_person() and d.revoked_at is null
       and d.post_key = any(p_posts)
       and d.starts_on <= current_date
       and (d.ends_on is null or d.ends_on >= current_date)
       and (v2.acting_school() is null or d.school_id = v2.acting_school()));
$function$
;
