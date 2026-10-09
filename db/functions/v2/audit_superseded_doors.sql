-- v2.audit_superseded_doors()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b30eaa3e678e89f705e78058c2dfd95e
CREATE OR REPLACE FUNCTION v2.audit_superseded_doors()
 RETURNS TABLE(fn text, note_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select n.nspname||'.'||p.proname||'('||pg_get_function_arguments(p.oid)||')',
         obj_description(p.oid,'pg_proc')
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname in ('v2','public') and p.prokind='f'
     and coalesce(obj_description(p.oid,'pg_proc'),'') ilike '%مُستبدَل%'
$function$
;
