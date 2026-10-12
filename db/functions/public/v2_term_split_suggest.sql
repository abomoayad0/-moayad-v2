-- public.v2_term_split_suggest(p_school uuid, p_grade smallint, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7123daf98211e5c0ff7beac9c4747400
CREATE OR REPLACE FUNCTION public.v2_term_split_suggest(p_school uuid, p_grade smallint, p_subject text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  v_mapped text[]; v_rep uuid; v_tot int; v_c1 int; v_c2 int;
  v_best smallint; v_best_gap numeric; v_cum int; v_target numeric;
  v_rows jsonb := '[]'::jsonb; r record; v_set smallint;
begin
  perform v2.assert_my_school(p_school,'اقتراحَ حدّ الفصلين');

  select array_agg(m.curriculum_subject_ar) into v_mapped
    from v2.curriculum_subject_map m where m.plan_subject_ar = btrim(p_subject);

  select t.section_id into v_rep
    from v2.timetable t join v2.class_sections c on c.id=t.section_id
   where t.school_id=p_school and c.grade=p_grade
     and t.subject_ar=btrim(p_subject) and t.slot_kind='teaching'
   group by t.section_id order by count(*) desc limit 1;
  if v_rep is null then
    raise exception 'لا حصصَ لمادّة «%» للصفّ % في جدول مدرستك — والسعةُ تُحسب على الجدول',
      btrim(p_subject), p_grade; end if;

  -- سعةُ كلّ فصلٍ من الجدول بعد خصم الإجازات، وبلا أسبوع الاختبار
  select
    coalesce(sum(case when x.term_no=1 then c.cap else 0 end),0),
    coalesce(sum(case when x.term_no=2 then c.cap else 0 end),0)
    into v_c1, v_c2
    from v2.school_weeks(p_school) x
    cross join lateral (select (select count(*) from v2.timetable t
        join v2.calendar_days d on d.week_id=x.week_id and d.day_kind='study'
             and extract(dow from d.on_g)::int = t.weekday
       where t.school_id=p_school and t.section_id=v_rep
         and t.subject_ar=btrim(p_subject) and t.slot_kind='teaching') as cap) c
   where not x.is_exam
     and x.week_no < coalesce((select min(y.week_no) from v2.school_weeks(p_school) y
                                where y.term_no=x.term_no and y.is_exam), 99);

  select coalesce(sum(coalesce(l.periods,1)),0) into v_tot
    from v2.curriculum_units u join v2.curriculum_lessons l on l.unit_id=u.id
   where u.grade=p_grade
     and (u.subject_ar=btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')));
  if v_tot = 0 then
    raise exception 'لا منهجَ منقولٌ لمادّة «%» في الصفّ %', btrim(p_subject), p_grade; end if;

  -- الحدُّ الأقربُ إلى نسبة السعتين، عند حدّ وحدةٍ
  v_target := v_tot::numeric * v_c1 / nullif(v_c1+v_c2,0);
  v_cum := 0; v_best := null; v_best_gap := null;
  for r in
    select u.unit_no, u.title_ar,
           (select coalesce(sum(coalesce(l.periods,1)),0) from v2.curriculum_lessons l where l.unit_id=u.id) per
      from v2.curriculum_units u
     where u.grade=p_grade
       and (u.subject_ar=btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')))
     order by u.ord nulls last, u.unit_no nulls last
  loop
    v_cum := v_cum + r.per;
    v_rows := v_rows || jsonb_build_object('unit_no',r.unit_no,'title_ar',r.title_ar,
                'periods',r.per,'cumulative',v_cum);
    if v_best is null or abs(v_cum - v_target) < v_best_gap then
      v_best := r.unit_no; v_best_gap := abs(v_cum - v_target);
    end if;
  end loop;

  select (select cumulative::int from jsonb_to_recordset(v_rows)
            as t(unit_no smallint, title_ar text, periods int, cumulative int)
           where t.unit_no = v_best) into v_cum;

  select term1_until_unit into v_set from v2.curriculum_term_split
   where grade=p_grade and subject_ar=btrim(p_subject);

  return jsonb_build_object(
    'grade',p_grade,'subject_ar',btrim(p_subject),
    'periods_total',v_tot,'cap_t1',v_c1,'cap_t2',v_c2,
    'suggest_until_unit',v_best,'suggest_t1_periods',v_cum,'suggest_t2_periods',v_tot-v_cum,
    'already_set',v_set,
    'units',v_rows,
    'fits', ( (v_cum <= v_c1) and ((v_tot-v_cum) <= v_c2) ),
    'summary_ar','أقترح أن ينتهي الفصلُ الأوّلُ بالوحدة '||v_best
      ||' — فيصير له '||v_cum||' حصّةً وسعتُه '||v_c1
      ||' · وللفصل الثاني '||(v_tot-v_cum)||' حصّةً وسعتُه '||v_c2,
    'note_ar', case when (v_cum <= v_c1) and ((v_tot-v_cum) <= v_c2)
        then 'والحدُّ يسع الفصلين. والقرارُ لك — يُقرّ أو يُعدَّل إلى وحدةٍ أخرى.'
        else '🔴 ولا حدَّ يجعل الفصلين يسعان منهجَهما — فالمنهجُ أكبرُ من نصاب السنة. '
             ||'والنصابُ والمنهجُ وزاريّان لا تُعدّلهما المدرسة، والمخرجُ دمجُ دروسٍ بيد المعلّم.' end);
end $function$
;
