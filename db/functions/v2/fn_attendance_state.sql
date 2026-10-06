-- v2.fn_attendance_state(p_student uuid, p_year uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2857b2b3741b633fb3e3c5a4cc8bf645
CREATE OR REPLACE FUNCTION v2.fn_attendance_state(p_student uuid, p_year uuid)
 RETURNS TABLE("أيام_بعذر" integer, "أيام_بلا_عذر" integer, "أيام_دراسة_مقررة" integer, "أيام_مرصودة" integer, "نسبة_الغياب" numeric, "الرصيد" numeric, "الحرمان" boolean, "تنبيه" text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with b as (
  select e.school_id sc, y.starts_on st, y.ends_on en from v2.enrolments e
  join v2.academic_years y on y.id=e.year_id
  where e.student_id=p_student and e.year_id=p_year limit 1),
d as (
  select v2.fn_absence_days(p_student,p_year,true) ex,
         v2.fn_absence_days(p_student,p_year,false) no_ex,
         (select count(*) from v2.attendance a where a.student_id=p_student and a.year_id=p_year) rec,
         (select v2.fn_school_days(b.sc, b.st, b.en) from b) sched,
         (select value_num from v2.conduct_rules where key='attendance.denial_pct') pct)
select ex, no_ex, sched, rec::int,
  case when coalesce(sched,0)=0 then 0 else round(no_ex::numeric*100/sched,2) end,
  v2.fn_attendance_balance(p_student,p_year),
  case when coalesce(sched,0)>0 and (no_ex::numeric*100/sched) > pct then true else false end,
  case
    when coalesce(sched,0)=0 then 'تقويم المدرسة غير منزَّل — لا تُحسب النسبة'
    when (no_ex::numeric*100/sched) > pct then 'تجاوز نسبة الغياب بدون عذر ('||pct||'%) — يُحرم من الانتقال · م31 بند 3'
    when (no_ex::numeric*100/sched) > pct*0.7 then 'اقترب من نسبة الحرمان'
    else 'ضمن الحدّ'
  end
from d;
$function$
;
