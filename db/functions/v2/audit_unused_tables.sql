-- v2.audit_unused_tables()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 13964764b70705123f31463d518752bb
CREATE OR REPLACE FUNCTION v2.audit_unused_tables()
 RETURNS TABLE(tbl text, why_ar text, severity text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; n bigint;
begin
  for r in
    select c.oid, c.relname from pg_class c join pg_namespace ns on ns.oid=c.relnamespace
     where ns.nspname='v2' and c.relkind='r' order by c.relname
  loop
    execute format('select count(*) from v2.%I', r.relname) into n;
    if n > 0 then continue; end if;
    if exists (select 1 from pg_proc p join pg_namespace n2 on n2.oid=p.pronamespace
                where n2.nspname in ('v2','public') and p.prokind='f'
                  and p.prosrc ~ ('v2\.'||r.relname||'\M')) then continue; end if;
    if exists (select 1 from pg_policy pl where pl.polrelid <> r.oid
                and coalesce(pg_get_expr(pl.polqual, pl.polrelid),'') ~ (r.relname||'\M')) then continue; end if;
    if exists (select 1 from pg_class v join pg_namespace n3 on n3.oid=v.relnamespace
                where n3.nspname in ('v2','public') and v.relkind in ('v','m')
                  and pg_get_viewdef(v.oid) ~ ('v2\.'||r.relname||'\M')) then continue; end if;
    tbl := r.relname;
    why_ar := 'جدولٌ مبنيٌّ صفرُ صفوفٍ ولا دالّةَ ولا سياسةَ ولا منظرَ يذكره — فإمّا نُسي أو استُغني عنه';
    severity := 'انتبه';
    return next;
  end loop;
end $function$
;
