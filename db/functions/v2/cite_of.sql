-- v2.cite_of(p_key text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3d2aafc891a6a351fd7e0672d0233833
CREATE OR REPLACE FUNCTION v2.cite_of(p_key text)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(c.source_doc||' '||c.source_page, '')||
         coalesce(' بند '||c.clause_no, '')
    from v2.citations c where c.key = p_key;
$function$
;
