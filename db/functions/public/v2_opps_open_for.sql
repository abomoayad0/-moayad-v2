-- public.v2_opps_open_for(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a34e898220e02d53083c0348de1c396c
CREATE OR REPLACE FUNCTION public.v2_opps_open_for(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; tm smallint; r jsonb; s jsonb;
begin
  perform v2.assert_my_student(p_student,'فرص التعويض');
  select e.school_id, e.year_id into sc, yr from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  tm := v2.fn_term_of(sc, current_date);
  s := v2.behavior_score(p_student, yr, tm);

  select jsonb_build_object(
    'score', s,
    'purpose', case when (s->>'deducted')::numeric > (s->>'restored')::numeric
                 then 'تعويضُ المحسوم أوّلًا — فإذا رجعتَ إلى ٨٠ فُتح لك الاكتساب'
                 else 'اكتسابُ سلوكٍ متميّز — لا محسومَ عليك' end,
    'open', (select coalesce(jsonb_agg(jsonb_build_object(
        'opp',o.id,'merit',m.text_ar,'group',m.group_ar,
        'points',m.points,'points_note',m.points_note,'source',m.source_page,
        'when',o.when_ar,'capacity',o.capacity,
        'taken',(select count(*) from v2.merit_entries x where x.opp_id=o.id),
        'joined',exists (select 1 from v2.merit_entries x
                          where x.opp_id=o.id and x.student_id=p_student))),'[]'::jsonb)
      from v2.merit_opportunities o join v2.conduct_merits m on m.id=o.merit_id
      where o.school_id=sc and o.state='مفتوحة'),
    'mine', (select coalesce(jsonb_agg(jsonb_build_object(
        'entry',x.id,'opp',o.id,'merit',m.text_ar,'when',o.when_ar,
        'state',o.state,'close_why',o.close_why,
        'filed',(x.filed_at is not null),'what',x.what_ar,'evidence',x.evidence_desc,
        'verdict',x.verdict,'note',x.verdict_note,
        'graded',(x.graded_at is not null),'points',x.points)),'[]'::jsonb)
      from v2.merit_entries x join v2.merit_opportunities o on o.id=x.opp_id
      join v2.conduct_merits m on m.id=o.merit_id
      where x.student_id=p_student)
  ) into r;
  return r;
end $function$
;
