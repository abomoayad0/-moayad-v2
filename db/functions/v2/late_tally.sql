-- v2.late_tally(p_school uuid, p_student uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b9c62fbf7f4b53a85f7a2f431eb00cd3
CREATE OR REPLACE FUNCTION v2.late_tally(p_school uuid, p_student uuid, p_term smallint)
 RETURNS TABLE(daily_n integer, period_n integer, total_n integer, excused_n integer, last_on date, over boolean, threshold integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with thr as (select v2.rule_n(p_school,'late_referral_over') t),
  ok as (  -- أعذارٌ مقبولةٌ تغطّي تواريخَ
    select c.from_date, c.to_date from v2.absence_excuse_claims c
     where c.student_id = p_student and c.decision = 'accepted'),
  d as (
    select a.on_date from v2.attendance a
     where a.school_id = p_school and a.student_id = p_student
       and a.term_no = p_term and a.state = 'late'
       and not exists (select 1 from ok where a.on_date between ok.from_date and ok.to_date)),
  p as (
    select pa.on_date from v2.period_attendance pa
     where pa.school_id = p_school and pa.student_id = p_student
       and pa.term_no = p_term and pa.state = 'late'
       and not exists (select 1 from ok where pa.on_date between ok.from_date and ok.to_date)),
  ex as (
    select count(*)::int n from (
      select a.on_date from v2.attendance a
       where a.school_id=p_school and a.student_id=p_student and a.term_no=p_term and a.state='late'
         and exists (select 1 from ok where a.on_date between ok.from_date and ok.to_date)
      union all
      select pa.on_date from v2.period_attendance pa
       where pa.school_id=p_school and pa.student_id=p_student and pa.term_no=p_term and pa.state='late'
         and exists (select 1 from ok where pa.on_date between ok.from_date and ok.to_date)) z)
  select (select count(*)::int from d),
         (select count(*)::int from p),
         (select count(*)::int from d) + (select count(*)::int from p),
         (select n from ex),
         greatest((select max(on_date) from d), (select max(on_date) from p)),
         ((select count(*) from d) + (select count(*) from p)) > (select t from thr),
         (select t from thr)
$function$
;
