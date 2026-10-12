-- v2.audit_doors_without_guard()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0bdffed1521979eed5ac6e4e1c30d311
CREATE OR REPLACE FUNCTION v2.audit_doors_without_guard()
 RETURNS TABLE(fn text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with recursive fns as (
    select p.oid, n.nspname, p.proname, p.prosrc, pg_get_function_arguments(p.oid) args
      from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname in ('v2','public') and p.prokind = 'f'
  ),
  -- الحرّاسُ الأصليّون بمبدأٍ لا بقائمة: مَن سأل الصفةَ أو المنحةَ أو قرأ هويّةَ المتّصل من الطلب
  g as (
    select f.proname from fns f
     where f.prosrc ~ ('assert_role|assert_my_school|assert_grant|assert_my_student'
                     ||'|assert_my_child|assert_attendance_hand|assert_student_or_kin'
                     ||'|plan_guard|my_school|my_post_keys|my_role|is_counselor|is_leader'
                     ||'|my_seat|my_grant|leads_school|current_person|auth\.uid|request\.jwt')
    union
    -- ومن ينادي حارسًا فهو محروسٌ بنداءه
    select f.proname from fns f join g on f.prosrc ~ ('\m'||g.proname||'\M')
     where f.proname <> g.proname
  )
  select 'public.'||f.proname||'('||f.args||')',
         'بابٌ يكتب في القاعدة ولا يسأل هويّةَ المتّصل بشيء — لا صفةً ولا منحةً ولا ملكيّة · '||
         'ولا ينادي بوّابةً تسألها. (والكاشفُ يتبع سلسلةَ النداء، فهذا كشفٌ لا ظنّ فيه)',
         'خلل'
    from fns f
   where f.nspname = 'public' and f.proname like 'v2\_%'
     and (f.prosrc ~ 'insert into v2\.' or f.prosrc ~ 'update v2\.' or f.prosrc ~ 'delete from v2\.')
     and f.proname not in (select proname from g)
   order by 1;
$function$
;
