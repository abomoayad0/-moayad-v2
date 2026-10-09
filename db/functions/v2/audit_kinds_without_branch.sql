-- v2.audit_kinds_without_branch()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7dd46f44adf962dcf7c6caa94675e2de
CREATE OR REPLACE FUNCTION v2.audit_kinds_without_branch()
 RETURNS TABLE(domain_ar text, engine text, kind text, items integer, why_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with eng as (
    select 'السلوك'::text dom, 'v2.ladder_auto'::text fn,
           (select p.prosrc from pg_proc p join pg_namespace n on n.oid=p.pronamespace
             where n.nspname='v2' and p.proname='ladder_auto') src
    union all
    select 'المواظبة', 'v2.absence_task_auto',
           (select p.prosrc from pg_proc p join pg_namespace n on n.oid=p.pronamespace
             where n.nspname='v2' and p.proname='absence_task_auto')
  ),
  kinds as (
    select 'السلوك'::text dom, i.kind, count(*)::int n
      from v2.conduct_action_items i group by 1,2
    union all
    select 'المواظبة', i.kind, count(*)::int
      from v2.absence_ladder_items i group by 1,2
  )
  select k.dom, e.fn, k.kind, k.n,
         'نوعٌ مزروعٌ في الدليل ولا يُذكر في محرّكه — فلا يخرج له ورقٌ آليًّا، ويمرّ بلا بيانٍ إن لم يكن ثمّ حارسٌ عامّ'
    from kinds k join eng e on e.dom = k.dom
   where position(k.kind in coalesce(e.src,'')) = 0
$function$
;
