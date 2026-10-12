-- v2.audit_health_case_due_review()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 67ebbc363285531d3eec3cc9f013e333
CREATE OR REPLACE FUNCTION v2.audit_health_case_due_review()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'حالةٌ صحيّةٌ لم تُراجَع · ' || v2.fn_display_name(st.full_name),
         'مضى على تسجيلها ' || v2.ar_num((current_date - c.from_on)) ||
         ' يومًا ولم تُراجَع، ومدّةُ المراجعة ' ||
         v2.ar_num(v2.rule_n(c.school_id,'health_review_days')) || ' يومًا من لوحة التحكّم',
         'انتبه'
    from v2.health_cases c
    join v2.students st on st.id = c.student_id
   where c.ended_at is null
     and coalesce(c.reviewed_on, c.from_on) < current_date - v2.rule_n(c.school_id,'health_review_days');
$function$
;
