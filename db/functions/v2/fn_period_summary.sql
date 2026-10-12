-- v2.fn_period_summary(p_section uuid, p_period smallint, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 711203006df80a20d061917537600e04
CREATE OR REPLACE FUNCTION v2.fn_period_summary(p_section uuid, p_period smallint, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(enrolled integer, recorded integer, unrecorded integer, present integer, absent integer, late integer, permitted integer, subject_ar text, teacher_ar text, starts_at time without time zone, ends_at time without time zone, is_done boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with l as (select * from v2.fn_period_list(p_section,p_period,p_date)),
s as (select cs.school_id sch from v2.class_sections cs where cs.id = p_section),
tr as (select t.* from s, v2.period_truth(s.sch, p_section, p_period, p_date) t)
select count(*)::int,
 count(*) filter (where period_state<>'unrecorded')::int,
 count(*) filter (where period_state='unrecorded')::int,
 count(*) filter (where period_state='present')::int,
 count(*) filter (where period_state='absent')::int,
 count(*) filter (where period_state='late')::int,
 count(*) filter (where period_state='permitted')::int,
 (select tr.subject_ar from tr),
 (select tr.person_ar || case when tr.basis='schedule' then ''
                              else ' · '||coalesce(tr.why_ar,'') end from tr),
 (select ps.starts_at from v2.period_slots ps, s where ps.school_id=s.sch and ps.period_no=p_period),
 (select ps.ends_at   from v2.period_slots ps, s where ps.school_id=s.sch and ps.period_no=p_period),
 count(*) filter (where period_state='unrecorded') = 0
from l
$function$
;
