-- public.v2_opps_open_for(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 60081f3ffc307f35382768ba50be01f0
CREATE OR REPLACE FUNCTION public.v2_opps_open_for(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; tm smallint; r jsonb; s jsonb; who text;
begin
  who := v2.caller_kind(p_student);
  if who = 'none' then raise exception 'لا تملك الاطّلاع على فرص هذا الطالب'; end if;
  if who not in ('student','guardian') then
    perform v2.assert_my_student(p_student,'فرص التعويض'); end if;

  select e.school_id, e.year_id into sc, yr from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  tm := coalesce(v2.term_of_strict(sc, current_date), 1);
  s := v2.behavior_score(p_student, yr, tm);

  select jsonb_build_object(
    'as', who, 'score', s,
    'purpose', case when (s->>'deducted')::numeric > (s->>'restored')::numeric
                 then 'تعويضُ المحسوم أوّلًا — فإذا رجعتَ إلى ٨٠ فُتح لك الاكتساب'
                 else 'اكتسابُ سلوكٍ متميّز — لا محسومَ عليك' end,
    'open', (select coalesce(jsonb_agg(jsonb_build_object(
        'opp',o.id,'merit',m.text_ar,'group',m.group_ar,
        'points',m.points,'points_ar',v2.ar_num(m.points),
        'points_note',m.points_note,'source',v2.page_ar(m.source_page),
        'when',o.when_ar,'capacity',o.capacity,
        'taken',(select count(*) from v2.merit_entries x where x.opp_id=o.id),
        'joined',exists (select 1 from v2.merit_entries x
                          where x.opp_id=o.id and x.student_id=p_student))),'[]'::jsonb)
      from v2.merit_opportunities o join v2.conduct_merits m on m.id=o.merit_id
      where o.school_id=sc and o.state='مفتوحة'),
    'mine', (select coalesce(jsonb_agg(jsonb_build_object(
        'entry',x.id,'opp',o.id,'merit',m.text_ar,'when',o.when_ar,
        'state',o.state,'close_why',o.close_why,
        'upload_to', v2.evidence_path_for(x.id),
        'filed',(x.filed_at is not null),'what',x.what_ar,'evidence',x.evidence_desc,
        'verdict',x.verdict,'note',x.verdict_note,
        'graded',(x.graded_at is not null),
        'points',x.points,'points_ar',v2.ar_num(x.points))),'[]'::jsonb)
      from v2.merit_entries x join v2.merit_opportunities o on o.id=x.opp_id
      join v2.conduct_merits m on m.id=o.merit_id
      where x.student_id=p_student)
  ) into r;
  return r;
end $function$
;
