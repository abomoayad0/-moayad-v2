-- v2.practice_weight(p_school uuid, p_code text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 87ae8181c5a9d6e720e54d530cb78044
CREATE OR REPLACE FUNCTION v2.practice_weight(p_school uuid, p_code text)
 RETURNS numeric
 LANGUAGE sql
 STABLE
AS $function$
  select coalesce(
    (select w.points from v2.practice_weights w
      where w.school_id = p_school and w.code = p_code and w.active),
    (select c.points from v2.class_practices c where c.code = p_code),
    0)::numeric
$function$
;
