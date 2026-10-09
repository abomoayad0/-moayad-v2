-- v2.audit_ladder_tables_unscoped()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3de694606031b2336e5faa8e633aeef5
CREATE OR REPLACE FUNCTION v2.audit_ladder_tables_unscoped()
 RETURNS TABLE(tbl text, bound_to text, why_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select distinct tc.table_name,
         ccu.table_name,
         'جدولُ مجالٍ يُشير إلى بندِ سلّمٍ ولم يُعلَن غرضُه في ladder_table_scope — '||
         'فلا تحكم عليه المرآةُ ولا تعرف أيَّ سلّمٍ يخدم'
    from information_schema.table_constraints tc
    join information_schema.constraint_column_usage ccu
      on ccu.constraint_name = tc.constraint_name
   where tc.table_schema='v2' and tc.constraint_type='FOREIGN KEY'
     and ccu.table_name in ('behavior_tasks','absence_tasks')
     and tc.table_name not in (select s.tbl from v2.ladder_table_scope s)
$function$
;
