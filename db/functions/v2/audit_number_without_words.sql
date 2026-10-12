-- v2.audit_number_without_words()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 aacca443693274a11c8b5e49dc955476
CREATE OR REPLACE FUNCTION v2.audit_number_without_words()
 RETURNS TABLE(fn text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with doors as (
  select p.oid, p.proname, p.prosrc, pg_get_function_result(p.oid) ret,
         p.proargnames, p.proargmodes, p.proallargtypes
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname like 'v2\_%'
),
outc as (
  select d.proname, u.nm, t.typname
    from doors d
    cross join lateral unnest(d.proargnames, d.proargmodes, d.proallargtypes)
         with ordinality as u(nm, md, ty, i)
    join pg_type t on t.oid = u.ty
   where d.proargmodes is not null and u.md = 't'
),
bare_cols as (
  select c.proname, c.nm
    from outc c
   where c.typname in ('int2','int4','int8','numeric')
     and c.nm not in ('ord','serial_no','form_no')
     and not exists (select 1 from outc s where s.proname = c.proname
                      and s.nm in (c.nm||'_ar',
                           regexp_replace(c.nm,'(_n|_no|_count|_days|_min|_minutes|_pct|_left|_max)$','')||'_ar'))
),
keys as (
  select distinct d.proname, t.mm[1] as key
    from doors d
    cross join lateral regexp_matches(d.prosrc, '''([a-z][a-z0-9_]*)''', 'g') as t(mm)
   where d.ret = 'jsonb'
),
bare_keys as (
  select k.proname, k.key
    from keys k
   where k.key not in ('ord','serial_no','form_no')
     and (k.key ~ '(_n|_no|_count|_days|_min|_minutes|_pct|_left|_max)$'
          or k.key in ('points','days','count','balance','stock','price','limit','period','minutes'))
     and not exists (select 1 from v2.rule_numbers rn where rn.key = k.key)
     and not exists (select 1 from keys s where s.proname = k.proname
                      and s.key in (k.key||'_ar',
                           regexp_replace(k.key,'(_n|_no|_count|_days|_min|_minutes|_pct|_left|_max)$','')||'_ar'))
)
select 'public.'||b.proname,
       'عمودٌ رقميٌّ يخرج بلا أخٍ يحمل نصَّه: '||string_agg(b.nm, ' · ' order by b.nm)||
       ' — وهذا كشفٌ يقينيٌّ من أعمدةِ الباب نفسِها لا ظنًّا من نصِّه.',
       'انتبه'
  from bare_cols b group by b.proname
union all
select 'public.'||k.proname,
       'مفتاحٌ رقميٌّ لا يُرى بجانبه مفتاحٌ بنصِّه: '||string_agg(k.key, ' · ' order by k.key)||
       ' — كشفٌ ظنّيٌّ من نصِّ الباب يُراجَع، إلى أن يُبنى نداءُ الأبواب الحقيقيُّ فيصير يقينًا.',
       'انتبه'
  from bare_keys k group by k.proname;
$function$
;
