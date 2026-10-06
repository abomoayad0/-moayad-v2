-- v2.is_counselor(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3e0cf72cf4c9b7aebca5d016ac5f5039
CREATE OR REPLACE FUNCTION v2.is_counselor(p_school uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare chosen text;
begin
  if not exists (select 1 from v2.assignments a
                  where a.person_id=v2.current_person() and a.school_id=p_school
                    and a.post_key='counselor' and a.ended_on is null) then
    return false; end if;
  select role_key into chosen from v2.session_role where user_id = auth.uid();
  if chosen is not null and chosen <> 'counselor' then
    return false; end if;
  return true;
end $function$
;
