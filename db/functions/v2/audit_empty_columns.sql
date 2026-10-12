-- v2.audit_empty_columns()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 750c278c992552d093e03d77fd33e9aa
CREATE OR REPLACE FUNCTION v2.audit_empty_columns()
 RETURNS TABLE(col text, rows_n bigint, why_ar text, severity text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; n bigint; m bigint;
begin
  for r in
    select c.relname tbl, a.attname cl
      from pg_class c join pg_namespace ns on ns.oid=c.relnamespace
      join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
     where ns.nspname='v2' and c.relkind='r'
       and coalesce(c.reltuples,0) between 1 and 200000
       and not a.attnotnull
     order by c.relname, a.attnum
  loop
    execute format('select count(*), count(%I) from v2.%I', r.cl, r.tbl) into n, m;
    if n > 0 and m = 0 then
      col := r.tbl||'.'||r.cl; rows_n := n;
      why_ar := 'عمودٌ فيه '||n::text||' صفًّا ولم يُكتب فيه شيءٌ قطّ — فإمّا بابُه لم يُبنَ أو استُغني عنه';
      severity := 'انتبه';
      return next;
    end if;
  end loop;
end $function$
;
