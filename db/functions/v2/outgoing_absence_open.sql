-- v2.outgoing_absence_open(p_mail uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bb71d542c1de0f79bc1913000d406731
CREATE OR REPLACE FUNCTION v2.outgoing_absence_open(p_mail uuid)
 RETURNS integer
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select count(*)::int from v2.outgoing_links lt
    join v2.absence_tasks ab on ab.id = lt.source_id and lt.source = 'absence'
   where lt.mail_id = p_mail and ab.status <> 'done';
$function$
;
