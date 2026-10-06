-- v2.my_posts()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 016ae271d16a2bed39cd7e44eac7acd7
CREATE OR REPLACE FUNCTION v2.my_posts()
 RETURNS TABLE(school_id uuid, post_key text, label_ar text, is_assignment boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  -- ① التكاليف النافذة اليوم
  select a.school_id, a.post_key, p.label_ar, true
  from v2.app_users u
  join v2.assignments a on a.person_id = u.person_id
  join v2.posts p on p.key = a.post_key
  where u.id = auth.uid() and u.is_active
    and a.started_on <= current_date
    and (a.ended_on is null or a.ended_on >= current_date)
  union all
  -- ② الوظيفة في الملاك إن لم يكن له تكليف
  select s.id, pe.post_key, p.label_ar, false
  from v2.app_users u
  join v2.people pe on pe.id = u.person_id
  join v2.posts p on p.key = pe.post_key
  cross join v2.schools s
  where u.id = auth.uid() and u.is_active and pe.post_key is not null
    and s.tenant_id = u.tenant_id
    and (u.school_id is null or u.school_id = s.id)
$function$
;
