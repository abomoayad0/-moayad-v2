-- v2.fn_my_roles()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ac2874ab7439b605bcabb0b40b0d8092
CREATE OR REPLACE FUNCTION v2.fn_my_roles()
 RETURNS TABLE(role_key text, role_ar text, source text, school_id uuid, school_ar text, is_current boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with u as (select * from v2.app_users where id=auth.uid() and is_active),
cur as (select role_key, school_id from v2.session_role where user_id=auth.uid())
select a.post_key, ps.label_ar, 'تكليف', a.school_id, s.name_ar,
  (a.post_key = (select role_key from cur) and a.school_id is not distinct from (select school_id from cur))
from v2.assignments a join u on u.person_id=a.person_id
join v2.posts ps on ps.key=a.post_key join v2.schools s on s.id=a.school_id
where a.ended_on is null
union all
select pe.post_key, ps.label_ar, 'الوظيفة في الملاك', null, null,
  (pe.post_key = (select role_key from cur) and (select school_id from cur) is null)
from v2.people pe join u on u.person_id=pe.id
join v2.posts ps on ps.key=pe.post_key
where pe.post_key is not null
$function$
;
