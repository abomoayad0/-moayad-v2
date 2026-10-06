-- v2.fn_find_student(p_q text, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e594d834c6e4258e876ff3a1f8c79491
CREATE OR REPLACE FUNCTION v2.fn_find_student(p_q text, p_school uuid DEFAULT NULL::uuid)
 RETURNS TABLE(student_id uuid, display_name text, full_name text, student_no text, national_id text, grade smallint, section text, school text, guardian_name text, guardian_phone text, matched_on text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with q as (
  select v2.fn_norm_ar(p_q) as qn,
         v2.fn_digits(p_q)  as qd,
         string_to_array(v2.fn_norm_ar(p_q), ' ') as words
)
select s.id, v2.fn_display_name(s.full_name), s.full_name, s.student_no, s.national_id,
       e.grade, e.section, sc.name_ar,
       g.full_name, g.phone,
       case
         when q.qd <> '' and s.student_no = q.qd then 'رقم الطالب'
         when q.qd <> '' and s.national_id = q.qd then 'رقم الهوية'
         when q.qd <> '' and right(v2.fn_digits(g.phone), 9) = right(q.qd, 9) then 'جوال ولي الأمر'
         when q.qn is not null and v2.fn_norm_ar(g.full_name) like '%'||q.qn||'%' then 'اسم ولي الأمر'
         else 'اسم الطالب'
       end
from v2.students s
join q on true
join v2.enrolments e on e.student_id = s.id and e.status='active'
join v2.schools sc on sc.id = s.school_id
left join v2.guardians g on g.student_id = s.id and g.is_primary
where (p_school is null or s.school_id = p_school)
  and (
    (q.qd <> '' and length(q.qd) >= 4 and (
        s.student_no = q.qd or s.national_id = q.qd
        or v2.fn_digits(s.passport_no) = q.qd
        or v2.fn_digits(g.national_id) = q.qd
        or (length(q.qd) >= 7 and right(v2.fn_digits(g.phone), 9) = right(q.qd, 9))
    ))
    or (q.qn is not null and (
        select bool_and(
          v2.fn_norm_ar(s.full_name) like '%'||w||'%'
          or v2.fn_norm_ar(v2.fn_display_name(s.full_name)) like '%'||w||'%'
          or v2.fn_norm_ar(g.full_name) like '%'||w||'%'
          or coalesce(upper(s.full_name_en),'') like '%'||upper(w)||'%'
        ) from unnest(q.words) w where w <> ''
    ))
  )
order by e.grade, s.student_no;
$function$
;
