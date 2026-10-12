-- v2.audit_raw_timetable_readers()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 205f05e88a311221eb800dc19706ed39
CREATE OR REPLACE FUNCTION v2.audit_raw_timetable_readers()
 RETURNS TABLE(fn text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select n.nspname||'.'||p.proname,
         'يقرأ جدولَ الحصص الخامَ في يومٍ بعينه ولا يسأل v2.period_truth — فلا يرى تبديلًا ولا تغطية',
         'انتبه'
    from pg_proc p join pg_namespace n on n.oid=p.pronamespace
   where n.nspname in ('v2','public') and p.prokind='f'
     and p.prosrc ~ 'v2\.timetable'
     and (p.prosrc ~ 'current_date' or p.prosrc ~ 'p_date' or p.prosrc ~ 'on_date')
     and p.prosrc !~ 'period_truth' and p.prosrc !~ 'effective_periods'
     and p.proname not in ('period_truth','effective_periods','swap_of','swap_matches',
       'cover_candidates','cover_run','cover_gap_why','cover_plan','cover_fairness',
       'v2_timetable_suggest','v2_slot_save','v2_slot_check','v2_slot_delete',
       'v2_timetable_board','v2_section_timetable','fn_section_timetable',
       'v2_swap_request','v2_swap_matches','v2_swap_options','v2_swaps_board',
       'v2_cover_run','v2_cover_board','v2_cover_plan','v2_cover_set','v2_absent_today',
       'v2_draft_apply','v2_audit_raw_timetable_readers','plan_sections','teacher_quota',
       -- خانةُ الحصّة العلاجيّة بلا فصل · فلا يقع عليها تبديلٌ ولا تغطيةٌ أصلًا
       'remedial_day')
     and p.proname !~ '^audit'
   order by 1
$function$
;
