-- public.v2_my_sections(p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 af4387e5a0c52f7f7fb259b469242658
CREATE OR REPLACE FUNCTION public.v2_my_sections(p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(section_id uuid, class_ar text, period_no smallint, starts_at time without time zone, ends_at time without time zone, subject_ar text, state text, students_n integer, recorded_n integer, is_done boolean, period_ar text, at_ar text, students_ar text, recorded_ar text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with d as (select (now() at time zone 'Asia/Riyadh')::time tt,
                  v2.acting_school() sch, v2.current_person() me),
mine as (
  select e.section_id, e.period_no, e.subject_ar, e.basis, e.from_ar
    from d, v2.effective_periods(d.sch, d.me, p_date) e
   where not exists (
     select 1 from v2.period_covers c
      where c.school_id = d.sch and c.on_date = p_date
        and c.period_no = e.period_no and c.section_id = e.section_id
        and c.voided_at is null
        and coalesce(c.cover_person,'00000000-0000-0000-0000-000000000000'::uuid) <> d.me)
  union all
  select c.section_id, c.period_no, c.subject_ar, 'cover'::text,
         (select v2.fn_display_name(pa.full_name) from v2.people pa where pa.id = c.absent_person)
    from d join v2.period_covers c
      on c.school_id = d.sch and c.on_date = p_date
     and c.cover_person = d.me and c.voided_at is null
),
rows as (
select cs.id as section_id,
       cs.label_ar || case m.basis
         when 'swap'  then ' · تبديلٌ من '||coalesce(m.from_ar,'—')
         when 'cover' then ' · تغطيةُ '||coalesce(m.from_ar,'—')
         else '' end as class_ar,
       ps.period_no, ps.starts_at, ps.ends_at, m.subject_ar,
       case when (select tt from d) between ps.starts_at and ps.ends_at then 'الآن'
            when ps.starts_at > (select tt from d) then 'قادمة' else 'انتهت' end as state,
       (select count(*)::int from v2.enrolments e where e.school_id=cs.school_id
         and e.grade=cs.grade and e.section=cs.section and e.status='active') as students_n,
       (select count(*)::int from v2.period_attendance pa join v2.enrolments e2 on e2.student_id=pa.student_id
         where pa.on_date=p_date and pa.period_no=ps.period_no and e2.school_id=cs.school_id
           and e2.grade=cs.grade and e2.section=cs.section and e2.status='active') as recorded_n,
       (select count(*) from v2.enrolments e3 where e3.school_id=cs.school_id and e3.grade=cs.grade
          and e3.section=cs.section and e3.status='active')
       = (select count(*) from v2.period_attendance pa2 join v2.enrolments e4 on e4.student_id=pa2.student_id
          where pa2.on_date=p_date and pa2.period_no=ps.period_no and e4.school_id=cs.school_id
            and e4.grade=cs.grade and e4.section=cs.section and e4.status='active') as is_done
from mine m
join v2.class_sections cs on cs.id = m.section_id
join v2.period_slots ps on ps.school_id = cs.school_id and ps.period_no = m.period_no
)
select r.section_id, r.class_ar, r.period_no, r.starts_at, r.ends_at, r.subject_ar, r.state,
       r.students_n, r.recorded_n, r.is_done,
       v2.period_ar(r.period_no),
       v2.time_ar(r.starts_at)||' — '||v2.time_ar(r.ends_at),
       v2.ar_count0(r.students_n,'لا طالبَ في الفصل','طالبٌ واحد','طالبان','طلّاب','طالبًا'),
       case when r.students_n = 0 then 'لا طالبَ في الفصل'
            when r.recorded_n = 0 then 'لم يُرصد أحدٌ من '||
                 v2.ar_count(r.students_n,'طالبٍ واحد','طالبين','طلّاب','طالبًا')
            when r.is_done then 'رُصد الجميع · '||
                 v2.ar_count(r.students_n,'طالبٌ واحد','طالبان','طلّاب','طالبًا')
            else 'رُصد '||v2.ar_num(r.recorded_n)||' من '||
                 v2.ar_count(r.students_n,'طالبٍ واحد','طالبين','طلّاب','طالبًا') end
  from rows r
 order by r.period_no
$function$
;
