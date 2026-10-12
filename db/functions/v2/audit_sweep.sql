-- v2.audit_sweep()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 252e40a28b144fb0974d846ac66f569e
CREATE OR REPLACE FUNCTION v2.audit_sweep()
 RETURNS TABLE(check_key text, object_ar text, detail_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'doors_without_guard', x.fn, x.why_ar, x.severity from v2.audit_doors_without_guard() x
  union all select 'open_doors', y.fn, y.why_ar, y.severity from v2.audit_open_doors() y
            where y.severity='خلل'
  union all select 'raw_timetable', z.fn, z.why_ar, 'خلل' from v2.audit_raw_timetable_readers() z
  union all select 'hardcoded_numbers', h.fn, 'الأرقام: '||h.hits||' — '||h.why_ar, 'خلل'
            from v2.audit_hardcoded_numbers() h
  union all select 'doors_without_source', s.fn, s.why_ar, s.severity from v2.audit_doors_without_source() s
  union all select 'unused_tables', u.tbl, u.why_ar, u.severity from v2.audit_unused_tables() u
  union all select 'empty_columns', e.col, e.why_ar, e.severity from v2.audit_empty_columns() e
  union all select 'late_referral_due', l.obj, l.why_ar, l.severity from v2.audit_late_referral_due() l
  union all select 'staff_late_due', f.obj, f.why_ar, f.severity from v2.audit_staff_late_due() f
  union all select 'reading_due', g.obj, g.why_ar, g.severity from v2.audit_reading_due() g
  union all select 'skill_never_measured', k.obj, k.why_ar, k.severity from v2.audit_skill_never_measured() k
  union all select 'assess_report_due', q.obj, q.why_ar, q.severity from v2.audit_assess_report_due() q
  union all select 'remedial_follow_due', rf.obj, rf.why_ar, rf.severity from v2.audit_remedial_follow_due() rf
  union all select 'remedial_evaluate_due', re.obj, re.why_ar, re.severity from v2.audit_remedial_evaluate_due() re
  union all select 'card_unlinked', cu.obj, cu.why_ar, cu.severity from v2.audit_card_unlinked() cu
  union all select 'card_step_late', cs.obj, cs.why_ar, cs.severity from v2.audit_card_step_late() cs
  union all select 'work_unseen', wu.obj, wu.why_ar, wu.severity from v2.audit_work_unseen() wu
  union all select 'exit_open', xo.obj, xo.why_ar, xo.severity from v2.audit_exit_open() xo
  union all select 'session_missing', sm.obj, sm.why_ar, sm.severity from v2.audit_session_missing() sm
  union all select 'session_incomplete', si.obj, si.why_ar, si.severity from v2.audit_session_incomplete() si
  union all select 'loyalty_unreachable', lu.obj, lu.why_ar, lu.severity from v2.audit_loyalty_unreachable() lu
  union all select 'health_no_counselor', hn.obj, hn.why_ar, hn.severity from v2.audit_health_no_counselor() hn
  union all select 'health_case_due_review', hr.obj, hr.why_ar, hr.severity from v2.audit_health_case_due_review() hr
  union all select 'number_without_words', nw.fn, nw.why_ar, nw.severity from v2.audit_number_without_words() nw
$function$
;
