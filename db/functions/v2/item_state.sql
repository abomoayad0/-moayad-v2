-- v2.item_state(p_item uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 91d13e84ec1e6b6ead64c052a73d67c0
CREATE OR REPLACE FUNCTION v2.item_state(p_item uuid)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with secs as (select count(*)::int n from v2.plan_sections(
                  (select plan_id from v2.lesson_plan_items where id = p_item))),
  pr as (select state, count(*)::int n from v2.lesson_item_progress
          where item_id = p_item and voided_at is null group by state)
  select case
    when (select coalesce(sum(n),0) from pr) = 0 then 'planned'
    when (select coalesce(max(n),0) from pr where state='lost') > 0 then 'lost'
    when (select coalesce(max(n),0) from pr where state='deferred') > 0 then 'deferred'
    when (select coalesce(max(n),0) from pr where state='done')
         >= greatest((select n from secs),1) then 'done'
    else 'planned' end;
$function$
;
