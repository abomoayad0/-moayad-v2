-- v2.audit_ladder_tables()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cc6a32b753df2e62f6a176e74b3f059c
CREATE OR REPLACE FUNCTION v2.audit_ladder_tables()
 RETURNS TABLE(tbl text, bound_ar text, polymorphic boolean, cross_ladder boolean, other_items integer, other_sample text, verdict_ar text, note_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with scope as (select * from v2.ladder_table_scope),
  shape as (
    select s.tbl,
           exists (select 1 from information_schema.columns c
                    where c.table_schema='v2' and c.table_name=s.tbl and c.column_name='source')
             and exists (select 1 from information_schema.columns c
                    where c.table_schema='v2' and c.table_name=s.tbl and c.column_name='source_id')
             as poly,
           coalesce((select string_agg(distinct ccu.table_name, ' و')
                       from information_schema.table_constraints tc
                       join information_schema.key_column_usage k
                         on k.constraint_name=tc.constraint_name
                       join information_schema.constraint_column_usage ccu
                         on ccu.constraint_name=tc.constraint_name
                      where tc.table_schema='v2' and tc.table_name=s.tbl
                        and tc.constraint_type='FOREIGN KEY'
                        and ccu.table_name in ('behavior_tasks','absence_tasks')), '—') bound
      from scope s
  ),
  other as (  -- بنودُ السلّم الآخر من الأنواع التي يخدمها الجدول
    select s.tbl,
           count(i.*)::int n,
           left(min(i.text_ar),70) sample
      from scope s
      left join v2.absence_ladder_items i on i.kind = any (s.serves_kinds)
     group by s.tbl
  )
  select s.tbl,
         case when h.bound='—' then 'غيرُ مشدودٍ إلى بندٍ' else 'مشدودٌ إلى '||h.bound end,
         h.poly, s.cross_ladder, o.n, o.sample,
         case
           when h.poly then 'مرنٌ — يقبل السلّمين'
           when s.cross_ladder and o.n > 0 then
             'نقصٌ — غرضُه عابرٌ للسلّمين، وفي سلّم المواظبة '||
             v2.ar_count(o.n,'بندٌ واحدٌ يخدمه','بندان يخدمهما','بنودٍ يخدمها','بندًا يخدمه')||
             ' ولا يقبلها'
           when s.cross_ladder then 'غرضُه عابرٌ ولا بندَ في السلّم الآخر بعد — فلا نقصَ اليوم'
           when o.n > 0 then
             'ليس نقصًا بإعلانٍ — وفي السلّم الآخر '||v2.ar_num(o.n)||
             ' بندًا من نوعه، فإن كان الإعلانُ خطأً فهذا دليلُه'
           else 'ليس نقصًا — ولا بندَ في السلّم الآخر من نوعه'
         end,
         s.note_ar
    from scope s join shape h on h.tbl=s.tbl join other o on o.tbl=s.tbl
$function$
;
