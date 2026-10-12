-- public.v2_curriculum_of(p_grade smallint, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e71661eeeb4ec031ed44c9576c7f1949
CREATE OR REPLACE FUNCTION public.v2_curriculum_of(p_grade smallint, p_subject text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; n int; v_src text[];
begin
  if auth.uid() is null then
    raise exception 'لا بدّ من تسجيل الدخول — ولا يُقبل قراءةُ المنهج بلا هويّة'; end if;

  -- أسماءُ المصدر التي تُقابل هذي المادّةَ في خطّتنا
  select coalesce(array_agg(m.curriculum_subject_ar),array[]::text[]) into v_src
    from v2.curriculum_subject_map m where m.plan_subject_ar = p_subject;
  v_src := v_src || p_subject;

  select coalesce(jsonb_agg(x order by (x->>'unit_no')::int nulls last, x->>'unit'),'[]'::jsonb), count(*)
    into r, n
  from (
    select jsonb_build_object(
      'unit', u.id, 'unit_no', u.unit_no, 'unit_ar', u.title_ar,
      'term_no', u.term_no, 'subject_src', u.subject_ar, 'is_branch', u.is_branch,
      'source_doc', u.source_doc, 'verified', u.verified,
      'periods', (select coalesce(sum(l.periods),0) from v2.curriculum_lessons l where l.unit_id=u.id),
      'lessons', coalesce((select jsonb_agg(jsonb_build_object(
            'lesson', l.id, 'no', l.lesson_no, 'title', l.title_ar,
            'periods', l.periods, 'outcomes', l.outcomes, 'verified', l.verified)
          order by l.ord nulls last, l.lesson_no nulls last)
        from v2.curriculum_lessons l where l.unit_id=u.id),'[]'::jsonb)) x
      from v2.curriculum_units u
     where u.grade = p_grade and u.subject_ar = any(v_src)) q;

  return jsonb_build_object('rows', r, 'units', n,
    'periods_total', (select coalesce(sum(l.periods),0) from v2.curriculum_lessons l
                       join v2.curriculum_units u on u.id=l.unit_id
                      where u.grade=p_grade and u.subject_ar = any(v_src)),
    'summary_ar', case when n = 0
      then 'لا منهجَ منقولٌ لهذي المادّة في هذا الصفّ'
      else v2.ar_count(n,'وحدةٌ واحدة','وحدتان','وحداتٍ','وحدةً') end,
    'note_ar','المنهجُ منقولٌ من مؤيّد القديم ومصدرُه مكتوبٌ في كلّ وحدة · والنواتجُ فارغةٌ في أكثر الدروس ولم تُختلق');
end $function$
;
