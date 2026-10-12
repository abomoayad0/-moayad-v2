-- v2.audit_health_no_counselor()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c932c546c16815e75c1a291138b40f8a
CREATE OR REPLACE FUNCTION v2.audit_health_no_counselor()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'لا موجّهَ صحيًّا مكلَّفًا · ' || s.name_ar,
         'المدرسةُ فيها ' || v2.ar_num((select count(*) from v2.enrolments e
             where e.school_id=s.id and e.status='active')) ||
         ' طالبًا ولا موجّهَ صحيًّا مكلَّفًا — فتبويبُ «صحّته» يُعرض ولا يُكتب فيه أحد. '
         || v2.cite_of('health.counselor_owns'),
         'خلل'
    from v2.schools s
   where exists (select 1 from v2.enrolments e where e.school_id=s.id and e.status='active')
     and not exists (select 1 from v2.assignments a
         where a.school_id=s.id and a.post_key='health_counselor' and a.ended_on is null);
$function$
;
