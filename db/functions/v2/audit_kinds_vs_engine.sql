-- v2.audit_kinds_vs_engine()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8b9fc9b455266e5068d48962e1d8c64c
CREATE OR REPLACE FUNCTION v2.audit_kinds_vs_engine()
 RETURNS TABLE(domain_ar text, engine text, kind text, items integer, has_form boolean, verdict_ar text, why_ar text)
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
    select 'السلوك'::text dom, i.kind, count(*)::int n from v2.conduct_action_items i group by 1,2
    union all
    select 'المواظبة', i.kind, count(*)::int from v2.absence_ladder_items i group by 1,2
  )
  select k.dom, e.fn, k.kind, k.n,
         (v2.form_for_kind(k.kind) is not null),
         case when v2.form_for_kind(k.kind) is not null
              then 'نقصٌ — للنوع نموذجٌ مضبوطٌ ولا فرعَ يُخرجه، فيبقى الورقُ منتظرًا يدًا'
              else 'ليس نقصًا — نوعٌ يدويٌّ بالتصميم: لا نموذجَ له، ويُقفل بإثباتٍ من باب الإثبات' end,
         'يُقاس بالورق لا بالاسم: النوعُ الذي أوجب الدليلُ له نموذجًا ينبغي أن يُخرجه المحرّك · '||
         'والذي لا نموذجَ له يُفعل بالعين واليد ويُقفل بشاهد'
    from kinds k join eng e on e.dom = k.dom
   where position(k.kind in coalesce(e.src,'')) = 0
$function$
;
