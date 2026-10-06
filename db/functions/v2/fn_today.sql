-- v2.fn_today(p_school text, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cfd6bfd60775b8c7c4e17ac2c471cc80
CREATE OR REPLACE FUNCTION v2.fn_today(p_school text, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("الطالب" text, "الصف" text, "الحالة" text, "التفصيل" text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select v2.fn_display_name(s.full_name), e.grade||'/'||e.section,
  case a.state when 'absent' then '🔴 غياب' when 'late' then '🟡 تأخر' else '🟢 حاضر' end,
  coalesce(case a.assembly_state
    when 'missed_inside' then 'في المدرسة ولم يحضر الاصطفاف'
    when 'late_inside' then 'تأخر عن الاصطفاف'
    when 'not_arrived' then case when a.arrived_at is not null
       then 'وصل '||a.arrived_at||' — متأخر '||a.minutes_from_assembly||' دقيقة' else 'لم يصل' end
    else 'حضر الاصطفاف' end,'')
from v2.attendance a
join v2.students s on s.id=a.student_id
join v2.enrolments e on e.student_id=s.id and e.status='active'
join v2.schools sc on sc.id=a.school_id
where sc.name_ar like '%'||p_school||'%' and a.on_date=p_date and a.state<>'present'
order by a.state, s.student_no;
$function$
;
