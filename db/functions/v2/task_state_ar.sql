-- v2.task_state_ar(p_status text, p_standing boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dab139b605dc7b5651946860cba330f0
CREATE OR REPLACE FUNCTION v2.task_state_ar(p_status text, p_standing boolean DEFAULT false)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case v2.task_state(p_status, p_standing)
    when 'open'     then 'ينتظر فعلًا'
    when 'standing' then 'حالٌ مستمرّةٌ — تُعرض ولا تُطالَب'
    when 'done'     then 'تمَّ وله شاهد'
    when 'skipped'  then 'لا ينطبق — وسببُه مكتوب'
    when 'refused'  then 'امتنع — وسببُه مكتوب'
    else v2.task_state(p_status, p_standing) end;
$function$
;
