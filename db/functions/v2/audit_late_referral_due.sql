-- v2.audit_late_referral_due()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 37272daa90f2c3dd620bbb115e681b09
CREATE OR REPLACE FUNCTION v2.audit_late_referral_due()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select v2.fn_display_name(s.full_name)||' — '||sc.name_ar,
         'تأخّرُه '||v2.ar_count(t.total_n,'مرّةٌ واحدة','مرّتان','مرّاتٍ','مرّةً')||' بلا عذرٍ في الفصل '||v2.ar_num(tm.n)
           ||' والعتبةُ '||v2.ar_num(t.threshold)||' — ولم تقع إحالتُه إلى الموجّه الطلابيّ',
         'خلل'
    from v2.schools sc
    cross join lateral (select v2.fn_term_of(sc.id, current_date) n) tm
    join v2.enrolments e on e.school_id = sc.id and e.status='active'
    join v2.students s on s.id = e.student_id
    cross join lateral v2.late_tally(sc.id, e.student_id, tm.n) t
   where t.over
     and v2.late_referral_of(sc.id, e.student_id, tm.n) is null
   order by 1
$function$
;
