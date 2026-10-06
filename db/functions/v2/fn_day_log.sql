-- v2.fn_day_log(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 83431fecd93a30f5544a8d43b424badc
CREATE OR REPLACE FUNCTION v2.fn_day_log(p_school uuid, p_date date)
 RETURNS TABLE("الوقت" timestamp with time zone, "النوع" text, "الصف" text, "رقم_الطالب" text, "الطالب" text, "الواقعة" text, "الدرجة" text, "المسؤول" text, "الحالة" text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select a.created_at, 'مواظبة',
  e.grade||'/'||e.section, st.student_no, v2.fn_display_name(st.full_name),
  case a.state when 'absent' then 'غياب'||case when v2.fn_is_excused(st.id,a.on_date) then ' بعذر' else ' بدون عذر' end
       when 'late' then 'تأخر'||coalesce(' ('||a.minutes_late||' دقيقة)','')
       when 'permitted' then 'استئذان' else 'حضور' end,
  null, coalesce(p.full_name,'—'),
  case when a.state='present' then 'عادي'
       when a.pushed_to_noor then 'أُدخل في نور' else '🔴 لم يُدخل في نور' end
from v2.attendance a
join v2.students st on st.id=a.student_id
join v2.enrolments e on e.student_id=st.id and e.status='active'
left join v2.people p on p.id=a.recorded_by
where a.school_id=p_school and a.on_date=p_date and a.state<>'present'

union all

select r.created_at, 'سلوك',
  e.grade||'/'||e.section, st.student_no, v2.fn_display_name(st.full_name),
  pr.text_ar, v2.degree_ar(pr.degree_no)||' · التكرار '||r.occurrence_no||' · الإجراء '||r.step_no,
  coalesce(p.full_name,'—'),
  (select count(*) filter (where t.status='open') from v2.behavior_tasks t where t.record_id=r.id)||' مهمة مفتوحة'
from v2.behavior_records r
join v2.students st on st.id=r.student_id
join v2.enrolments e on e.student_id=st.id and e.status='active'
join v2.conduct_problems pr on pr.id=r.problem_id
left join v2.people p on p.id=r.recorded_by
where r.school_id=p_school and r.occurred_on=p_date

union all

select c.created_at, 'إجراء غياب',
  e.grade||'/'||e.section, st.student_no, v2.fn_display_name(st.full_name),
  'بلغ '||c.days_count||' أيام غياب'||case when c.excused then ' بعذر' else ' بدون عذر' end
    ||case when c.consecutive then ' — متصلة' else '' end,
  'الدرجة '||v2.ar_num(l.days)||' من السلّم', 'إدارة المدرسة',
  (select count(*) filter (where t.status='open') from v2.absence_tasks t where t.case_id=c.id)||' مهمة مفتوحة'
from v2.absence_cases c
join v2.absence_ladder l on l.id=c.ladder_id
join v2.students st on st.id=c.student_id
join v2.enrolments e on e.student_id=st.id and e.status='active'
where c.school_id=p_school and c.triggered_on=p_date
order by 1;
$function$
;
