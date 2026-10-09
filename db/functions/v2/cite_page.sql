-- v2.cite_page(p_key text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7b05e261aadb4c6ea7bb512096ae0329
CREATE OR REPLACE FUNCTION v2.cite_page(p_key text)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce((select c.source_page from v2.citations c where c.key = p_key),
                  (select r.source_page from v2.conduct_rules r where r.key = p_key));
$function$
;
