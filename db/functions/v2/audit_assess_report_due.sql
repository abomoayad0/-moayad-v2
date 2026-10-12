-- v2.audit_assess_report_due()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 97a400209cf0ed13996cccfff409737a
CREATE OR REPLACE FUNCTION v2.audit_assess_report_due()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select v2.fn_display_name(s.full_name)||' — '||sc.name_ar||' · الدورةُ '||v2.ar_num(sr.round_no),
         case when sr.weak and sr.expert_at is null
                then 'تقريرٌ لطالبٍ ذي ضعفٍ أكاديميٍّ ولم تُسجَّل استشارةُ المعلّم الخبير — س-٩-ا-١ خطوة ٠٣ ص٢٢٠'
              when sr.approved_at is null
                then 'تقريرٌ أُعدّ ولم يراجعه الوكيلُ للشؤون التعليميّة ولم يعتمده — س-٩-ا-١ خطوة ٠٤ ص٢٢٠'
              else 'تقريرٌ اعتُمد ولم يُشعَر وليُّ الأمر — س-٩-ا-١ خطوة ٠٥ ص٢٢٠ وسياسة ٠١ ص٢١٧' end,
         'خلل'
    from v2.skill_reports sr
    join v2.schools sc on sc.id = sr.school_id
    join v2.students s on s.id = sr.student_id
   where sr.voided_at is null
     and (sr.notified_at is null or (sr.weak and sr.expert_at is null))
   order by 1
$function$
;
