-- v2.audit_remedial_follow_due()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3943d1e93ebb857c96c53fbc6a1f4b96
CREATE OR REPLACE FUNCTION v2.audit_remedial_follow_due()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select v2.fn_display_name(st.full_name)||' — '||s.name_ar,
         'أُحيل في '||v2.fn_to_hijri(r.at_ts::date)||' ولم تُسجَّل له متابعةٌ · وأكثرُ المدّة '
           ||v2.ar_num(v2.rule_n(r.school_id,'remedial_follow_days'))||' يومًا (رقمٌ في لوحة التحكّم)',
         'خلل'
    from v2.remedial_referrals r
    join v2.students st on st.id=r.student_id
    join v2.schools  s  on s.id=r.school_id
   where r.voided_at is null and r.responded is null
     and r.at_ts::date < current_date - v2.rule_n(r.school_id,'remedial_follow_days')
   order by 1
$function$
;
