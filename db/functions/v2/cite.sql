-- v2.cite(p_key text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 acb36bc0049685871287043f05f4c4d3
CREATE OR REPLACE FUNCTION v2.cite(p_key text)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'م'||r.article_no||coalesce(' بند '||r.clause_no,'')||' · '||r.source_doc||' '||r.source_page
    from v2.conduct_rules r where r.key = p_key;
$function$
;
