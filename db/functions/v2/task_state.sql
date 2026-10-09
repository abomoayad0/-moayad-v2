-- v2.task_state(p_status text, p_standing boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cfc75e66eff5b7e3c6f7fa37783e0f72
CREATE OR REPLACE FUNCTION v2.task_state(p_status text, p_standing boolean DEFAULT false)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case
    when coalesce(p_standing,false) then 'standing'
    when p_status = 'auto'          then 'standing'          -- السلوك تاريخيًّا
    when p_status = 'not_required'  then 'skipped'           -- الوارد
    when p_status = 'in_progress'   then 'open'              -- الوارد
    when p_status = 'closed'        then 'done'              -- الوارد
    when p_status in ('open','done','skipped','refused') then p_status
    else p_status end;
$function$
;
