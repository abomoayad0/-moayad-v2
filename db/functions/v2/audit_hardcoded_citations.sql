-- v2.audit_hardcoded_citations()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2ac3a6f4cc367f78d1ae3684e889c5cc
CREATE OR REPLACE FUNCTION v2.audit_hardcoded_citations()
 RETURNS TABLE(fn text, pages text[], why_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select n.nspname||'.'||p.proname,
         array_agg(distinct m[1] order by m[1]),
         'صفحةٌ مكتوبةٌ في نصّ الدالّة — والصفحاتُ في conduct_rules و official_forms و conduct_problems · '||
         'فإن تغيّرت هناك بقيت هنا على خطئها'
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    cross join lateral regexp_matches(p.prosrc, '(ص[0-9٠-٩]{1,3})', 'g') m
   where n.nspname in ('v2','public') and p.prokind='f'
     and p.proname not in ('audit_hardcoded_citations','page_ar','audit_duplication')
   group by 1
$function$
;
