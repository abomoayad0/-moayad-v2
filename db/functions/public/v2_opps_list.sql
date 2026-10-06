-- public.v2_opps_list(p_school uuid, p_state text, p_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 14e598d79d51caf724865eb62ed62b72
CREATE OR REPLACE FUNCTION public.v2_opps_list(p_school uuid, p_state text, p_days integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'opp',o.id,'merit_id',o.merit_id,'merit',m.text_ar,'group',m.group_ar,
      'points',m.points,'points_note',m.points_note,'source',m.source_page,
      'kind',o.kind,'title',o.title_ar,'when',o.when_ar,
      'capacity',o.capacity,'state',o.state,'close_why',o.close_why,
      'held_by',(select v2.fn_display_name(full_name) from v2.people where id=o.held_by),
      'held_by_id',o.held_by,
      'opened_on',o.opened_at::date,
      'joined',(select count(*) from v2.merit_entries x where x.opp_id=o.id),
      'filed',(select count(*) from v2.merit_entries x where x.opp_id=o.id and x.filed_at is not null),
      'verdicted',(select count(*) from v2.merit_entries x where x.opp_id=o.id and x.verdict is not null),
      'graded',(select count(*) from v2.merit_entries x where x.opp_id=o.id and x.graded_at is not null),
      'plan_note',o.plan_note)
      order by o.opened_at desc),'[]'::jsonb)
  into r from v2.merit_opportunities o join v2.conduct_merits m on m.id=o.merit_id
  where o.school_id=p_school
    and (p_state is null or o.state=p_state)
    and (p_days is null or o.opened_at >= now() - (p_days||' days')::interval);
  return r;
end $function$
;
