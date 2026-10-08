-- v2.my_school(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d52318b95a57ad3aac0a331c823ba5ea
CREATE OR REPLACE FUNCTION v2.my_school(p_school uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  with me as (
    select (select sr.school_id from v2.session_role sr where sr.user_id = auth.uid()) pinned,
           (select u.school_id from v2.app_users u
             where u.id = auth.uid() and u.is_active) acct,
           (select u.person_id from v2.app_users u
             where u.id = auth.uid() and u.is_active) person
  )
  select auth.uid() is not null
     and exists (select 1 from v2.app_users u where u.id = auth.uid() and u.is_active)
     and exists (
       select 1 from v2.schools s, me
        where s.id = p_school
          and s.tenant_id = v2.current_tenant()
          and case
                -- ① صفةٌ مثبّتةٌ ⇒ هي وحدَها تحكم
                when me.pinned is not null then me.pinned = p_school
                -- ② وإلّا: مدرسةُ الحساب · أو حسابٌ بلا مدرسة · أو تكليفٌ نافذٌ فيها
                else me.acct is not distinct from p_school
                  or me.acct is null
                  or exists (select 1 from v2.assignments a
                              where a.person_id = me.person
                                and a.school_id = p_school
                                and a.started_on <= current_date
                                and (a.ended_on is null or a.ended_on >= current_date))
              end);
$function$
;
