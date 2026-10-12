-- v2.audit_number_without_words()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c6db4b1d51fb1ae4f87303447e735bd0
CREATE OR REPLACE FUNCTION v2.audit_number_without_words()
 RETURNS TABLE(fn text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'public.'||p.proname,
         'يرجع أعدادًا (count · days · minutes · max · warn · points) ولا يستعمل ar_num ولا ar_count — '
         || 'فالشاشةُ تصوغ اللفظَ بنفسها، وهذا نقضُ قاعدةِ «كلُّ عددٍ معه نصُّه». وهو كشفٌ ظنّيٌّ يُراجَع.',
         'انتبه'
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname like 'v2\_%'
     and p.prosrc ~ '''[a-z_]*(count|_days|minutes|_max|_warn|points|_left)[a-z_]*'''
     and p.prosrc !~ 'ar_num|ar_count'
     and pg_get_function_result(p.oid) = 'jsonb';
$function$
;
