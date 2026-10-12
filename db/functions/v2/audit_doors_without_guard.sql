-- v2.audit_doors_without_guard()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 00a650956855eeb8e77c75c806e1c524
CREATE OR REPLACE FUNCTION v2.audit_doors_without_guard()
 RETURNS TABLE(fn text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'public.'||p.proname||'('||pg_get_function_arguments(p.oid)||')',
         'بابٌ يكتب في القاعدة ولا يسأل هويّةَ المتّصل بشيء — لا صفةً ولا منحةً ولا ملكيّة',
         'خلل'
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname like 'v2\_%' and p.prokind='f'
     and (p.prosrc ~ 'insert into v2\.' or p.prosrc ~ 'update v2\.' or p.prosrc ~ 'delete from v2\.')
     -- ① حارسُ الصفة
     and p.prosrc !~ 'assert_role' and p.prosrc !~ 'assert_my_school'
     and p.prosrc !~ 'assert_grant' and p.prosrc !~ 'assert_my_student'
     and p.prosrc !~ 'assert_my_child' and p.prosrc !~ 'assert_attendance_hand'
     and p.prosrc !~ 'assert_student_or_kin' and p.prosrc !~ 'plan_guard'
     and p.prosrc !~ 'my_school' and p.prosrc !~ 'my_post_keys' and p.prosrc !~ 'my_role'
     and p.prosrc !~ 'is_counselor' and p.prosrc !~ 'is_leader' and p.prosrc !~ 'my_seat'
     -- ② حارسُ المنحة
     and p.prosrc !~ 'my_grant'
     -- ③ حارسُ الملكيّة: يقرأ هويّةَ المتّصل ويقارن بها
     and p.prosrc !~ 'current_person' and p.prosrc !~ 'auth\.uid'
   order by 1
$function$
;
