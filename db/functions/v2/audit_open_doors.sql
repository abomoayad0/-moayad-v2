-- v2.audit_open_doors()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2fa3f85157d0da45b299f4f9e68a34ff
CREATE OR REPLACE FUNCTION v2.audit_open_doors()
 RETURNS TABLE(fn text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select n.nspname||'.'||p.proname||'('||pg_get_function_arguments(p.oid)||')',
         case when (p.proname like 'v2\_%' or n.nspname='v2')
              then 'بابٌ من أبوابنا مفتوحٌ لغير المسجَّلين'
              else 'بابُ إضافةٍ خارجيّةٍ مفتوحٌ بحكم تثبيتها — يُعلَن ولا يُعَدّ خللًا في بنائنا' end,
         case when (p.proname like 'v2\_%' or n.nspname='v2') then 'خلل' else 'انتبه' end
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname in ('v2','public') and p.prokind='f'
     and (has_function_privilege('anon', p.oid, 'EXECUTE')
       or has_function_privilege('public', p.oid, 'EXECUTE'))
     and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')
   order by 3, 1
$function$
;
