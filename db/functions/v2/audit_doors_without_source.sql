-- v2.audit_doors_without_source()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 60dac81cff87d80b0e0de45c6a482ce5
CREATE OR REPLACE FUNCTION v2.audit_doors_without_source()
 RETURNS TABLE(fn text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'public.'||p.proname,
         'بابٌ يكتب أو يرفض ولا بيانَ له يقول سندَه — من الدليل أم قرارُ مدرسةٍ أم اجتهاد',
         'انتبه'
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname='public' and p.proname like 'v2\_%' and p.prokind='f'
     and (p.prosrc ~ 'insert into v2\.' or p.prosrc ~ 'update v2\.'
          or p.prosrc ~ 'raise exception')
     and coalesce(obj_description(p.oid,'pg_proc'),'') !~ '(ص[0-9٠-٩]|س-[0-9٠-٩]|قرار|اجتهاد|لائحة|الدليل|م[0-9٠-٩])'
   order by 1
$function$
;
