-- v2.my_school(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b8fcb354cb3ba346db588ae3f76ca761
CREATE OR REPLACE FUNCTION v2.my_school(p_school uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select exists (
    select 1 from v2.schools s
    where s.id = p_school
      and s.tenant_id = v2.current_tenant()
      and (
        -- محرّرُ SQL أو من لا صفَّ له: المجمّع كلُّه
        not exists (select 1 from v2.app_users u where u.id = auth.uid() and u.is_active)
        or (
          -- 🔑 الصفةُ المختارةُ إن كانت لمدرسةٍ بعينها فهي وحدَها
          coalesce(
            (select sr.school_id from v2.session_role sr where sr.user_id = auth.uid()),
            (select u.school_id from v2.app_users u where u.id = auth.uid() and u.is_active)
          ) is not distinct from p_school
          or coalesce(
               (select sr.school_id from v2.session_role sr where sr.user_id = auth.uid()),
               (select u.school_id from v2.app_users u where u.id = auth.uid() and u.is_active)
             ) is null
        )
      ));
$function$
;
