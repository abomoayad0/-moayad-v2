-- v2.swap_of(p_school uuid, p_date date, p_slot uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9d0881e8de653d2e82632a555e43c312
CREATE OR REPLACE FUNCTION v2.swap_of(p_school uuid, p_date date, p_slot uuid)
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select case when w.req_slot = p_slot then w.partner else w.requester end
    from v2.period_swaps w
   where w.school_id = p_school and w.on_date = p_date and w.status = 'done'
     and (w.req_slot = p_slot or w.partner_slot = p_slot)
   limit 1;
$function$
;
