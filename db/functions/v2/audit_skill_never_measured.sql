-- v2.audit_skill_never_measured()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 89f3e5b20993d043653c89849a4df913
CREATE OR REPLACE FUNCTION v2.audit_skill_never_measured()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select s.subject_ar||' · «'||s.title_ar||'» — '||sc.name_ar,
         'مهارةٌ مُدخلةٌ في قائمة المدرسة'
           ||case when s.grade is null then '' else ' للصفّ '||v2.ar_num(s.grade) end
           ||' ولم يُقَس فيها طالبٌ واحدٌ قطّ',
         'انتبه'
    from v2.skills s join v2.schools sc on sc.id = s.school_id
   where s.voided_at is null and s.active
     and not exists (select 1 from v2.skill_marks m where m.skill_id=s.id and m.voided_at is null)
   order by 1
$function$
;
