-- public.v2_skill_card(p_student uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ae030af6c6566f643da943da18022441
CREATE OR REPLACE FUNCTION public.v2_skill_card(p_student uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; tm smallint; r jsonb; n_ok int; n_no int; n_none int; nm text; v_grade smallint;
begin
  perform v2.assert_my_student(p_student,'قراءةَ بطاقة المهارات');
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  tm := coalesce(p_term, v2.fn_term_of(sc, current_date));
  select cs.grade into v_grade from v2.class_sections cs
    join v2.enrolments e2 on e2.school_id=cs.school_id and e2.grade=cs.grade and e2.section=cs.section
   where e2.student_id=p_student and e2.status='active' limit 1;

  select coalesce(jsonb_agg(jsonb_build_object(
      'skill', x.id, 'subject_ar', x.subject_ar, 'title_ar', x.title_ar,
      'kind_ar', case x.kind when 'minimum' then 'حدٌّ أدنى' else 'مستهدفة' end,
      'level', coalesce(x.level,'لم يُقَس'),
      'mastered', x.is_mastered,
      'on_date', x.on_date,
      'by_ar', coalesce(x.by_ar,'—'),
      'note_ar', coalesce(x.note_ar,'—')
    ) order by x.subject_ar, x.ord, x.title_ar), '[]'::jsonb),
    count(*) filter (where x.is_mastered is true),
    count(*) filter (where x.is_mastered is false),
    count(*) filter (where x.level is null)
    into r, n_ok, n_no, n_none
    from (select s.id, s.subject_ar, s.title_ar, s.kind, s.ord,
                 m.level, m.on_date, m.note_ar,
                 (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=m.recorded_by) by_ar,
                 (select l.is_mastered from v2.skill_levels l
                   where l.active and (l.school_id = sc or l.school_id is null)
                     and v2.ar_bare(l.label_ar) = v2.ar_bare(m.level)
                   order by (l.school_id is null) limit 1) is_mastered
            from v2.skills s
            left join lateral (
              select * from v2.skill_marks mm
               where mm.skill_id=s.id and mm.student_id=p_student
                 and mm.term_no=tm and mm.voided_at is null
               order by mm.on_date desc, mm.recorded_at desc limit 1) m on true
           where s.school_id=sc and s.voided_at is null and s.active
             and (s.grade is null or s.grade = v_grade)) x;

  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;
  return jsonb_build_object('ok',true,'student',nm,'term',tm,'rows',r,
    'mastered',n_ok,'unmastered',n_no,'unmeasured',n_none,
    'summary_ar', case when jsonb_array_length(r)=0
      then 'لا مهارةَ في قائمة المدرسة لهذا الصفّ بعد'
      else 'متقنٌ '||v2.ar_num(n_ok)||' · غيرُ متقنٍ '||v2.ar_num(n_no)||' · لم يُقَس '||v2.ar_num(n_none) end,
    'basis_ar','والإتقانُ يُقرأ من v2.skill_levels.is_mastered لا من مقارنةِ نصٍّ — فمستوًى تزيده المدرسةُ يُحسب على وجهه',
    'note_ar',v2.cite_of('assess.unmastered'));
end $function$
;
