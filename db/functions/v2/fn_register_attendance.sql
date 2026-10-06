-- v2.fn_register_attendance(p_school uuid, p_year uuid, p_from date, p_to date, p_grade smallint, p_section text, p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f9ed3b2bc92210927029bb70e234d57a
CREATE OR REPLACE FUNCTION v2.fn_register_attendance(p_school uuid DEFAULT NULL::uuid, p_year uuid DEFAULT NULL::uuid, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date, p_grade smallint DEFAULT NULL::smallint, p_section text DEFAULT NULL::text, p_student uuid DEFAULT NULL::uuid)
 RETURNS TABLE("المدرسة" text, "المرحلة" text, "الصف" smallint, "الفصل" text, "رقم_الطالب" text, "الطالب" text, "أيام_دراسة_مقررة" integer, "أيام_مرصودة" integer, "حضور" integer, "غياب_بعذر" integer, "غياب_بلا_عذر" integer, "تأخر" integer, "استئذان" integer, "نسبة_الغياب" numeric, "رصيد_المواظبة" numeric, "حرمان" boolean, "غير_مدخل_في_نور" integer)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with sched as (
  select s.id sid,
    v2.fn_school_days(s.id,
      coalesce(p_from,(select min(y.starts_on) from v2.academic_years y where y.school_id=s.id)),
      coalesce(p_to,  (select max(y.ends_on)   from v2.academic_years y where y.school_id=s.id))) n
  from v2.schools s)
select sc.name_ar,
  case e.stage when 'primary' then 'ابتدائية' when 'intermediate' then 'متوسطة'
       when 'secondary' then 'ثانوية' else e.stage end,
  e.grade, e.section, st.student_no, v2.fn_display_name(st.full_name),
  sd.n,
  count(a.id)::int,
  count(*) filter (where a.state='present')::int,
  count(*) filter (where a.state='absent' and v2.fn_is_excused(st.id,a.on_date))::int,
  count(*) filter (where a.state='absent' and not v2.fn_is_excused(st.id,a.on_date))::int,
  count(*) filter (where a.state='late')::int,
  count(*) filter (where a.state='permitted')::int,
  case when coalesce(sd.n,0)=0 then 0 else
    round(count(*) filter (where a.state='absent' and not v2.fn_is_excused(st.id,a.on_date))::numeric*100/sd.n,2) end,
  v2.fn_attendance_balance(st.id, e.year_id),
  case when coalesce(sd.n,0)>0 and
    (count(*) filter (where a.state='absent' and not v2.fn_is_excused(st.id,a.on_date))::numeric*100/sd.n)
    > (select value_num from v2.conduct_rules where key='attendance.denial_pct') then true else false end,
  count(*) filter (where a.state<>'present' and not a.pushed_to_noor)::int
from v2.students st
join v2.enrolments e on e.student_id=st.id and e.status='active'
join v2.schools sc on sc.id=st.school_id
join sched sd on sd.sid=st.school_id
left join v2.attendance a on a.student_id=st.id
  and (p_from is null or a.on_date >= p_from) and (p_to is null or a.on_date <= p_to)
where (p_school is null or st.school_id=p_school)
  and (p_year is null or e.year_id=p_year)
  and (p_grade is null or e.grade=p_grade)
  and (p_section is null or e.section=p_section)
  and (p_student is null or st.id=p_student)
group by sc.name_ar, e.stage, e.grade, e.section, st.student_no, st.full_name, st.id, e.year_id, sd.n
order by sc.name_ar, e.grade, e.section, st.student_no;
$function$
;
