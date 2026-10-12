-- v2.audit_remedial_evaluate_due()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 fb6ff169c98b00b2cda485bc165bee50
CREATE OR REPLACE FUNCTION v2.audit_remedial_evaluate_due()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'خطّةُ «'||p.title_ar||'» — '||s.name_ar,
         'اعتُمدت في '||v2.fn_to_hijri(p.approved_at::date)||' ولم تُقيَّم نتائجُها · ومؤشّرُ الإجراء نسبةُ التحسّن — '
           ||v2.cite_of('remedial.improve_rate'),
         'خلل'
    from v2.remedial_plans p
    join v2.schools s on s.id=p.school_id
   where p.voided_at is null and p.approved_at is not null and p.evaluated_at is null
     and p.approved_at::date < current_date - v2.rule_n(p.school_id,'remedial_evaluate_days')
   order by 1
$function$
;
