-- public.v2_opp_card(p_opp uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 43724f94ab011b6c4b78c1e884553f25
CREATE OR REPLACE FUNCTION public.v2_opp_card(p_opp uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  select jsonb_build_object(
    'opp', to_jsonb(o) - 'school_id',
    'merit', (select jsonb_build_object('id',m.id,'text',m.text_ar,'group',m.group_ar,
        'points',m.points,'points_note',m.points_note,'source',m.source_page,
        'open_points',(m.points is null))
      from v2.conduct_merits m where m.id=o.merit_id),
    'held_by', (select v2.fn_display_name(full_name) from v2.people where id=o.held_by),
    'held_by_id', o.held_by,
    'members', (select coalesce(jsonb_agg(jsonb_build_object(
        'entry',x.id,
        'student_id',x.student_id,
        'name',v2.fn_display_name(s.full_name),
        'upload_to', v2.evidence_path_for(x.id),
        'joined_as',x.joined_as,
        'filed',(x.filed_at is not null),'filed_as',x.filed_as,'what',x.what_ar,
        'evidence',x.evidence_desc,'evidence_path',x.evidence_name,
        'verdict',x.verdict,'note',x.verdict_note,
        'by',(select v2.fn_display_name(full_name) from v2.people where id=x.verdict_by),
        'delegated',(select v2.fn_display_name(full_name) from v2.people where id=x.delegated_to),
        'delegated_id',x.delegated_to,
        'graded',(x.graded_at is not null),'points',x.points) order by s.full_name),'[]'::jsonb)
      from v2.merit_entries x join v2.students s on s.id=x.student_id
      where x.opp_id=o.id)
  ) into r from v2.merit_opportunities o where o.id=p_opp;
  return r;
end $function$
;
