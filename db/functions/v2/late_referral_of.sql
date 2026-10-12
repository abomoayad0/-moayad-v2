-- v2.late_referral_of(p_school uuid, p_student uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 df15b146122df1449795b02d2532019c
CREATE OR REPLACE FUNCTION v2.late_referral_of(p_school uuid, p_student uuid, p_term smallint)
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select cc.id from v2.counsel_cases cc
   where cc.school_id = p_school and cc.student_id = p_student
     and cc.term_no = p_term and cc.problem_id is null
     and coalesce(cc.source_ar,'') like 'attendance.late_referral%'
   order by cc.opened_on desc limit 1
$function$
;
