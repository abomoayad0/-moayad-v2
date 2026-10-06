-- public.v2_meetings_list(p_school uuid, p_committee text, p_status text, p_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 61452cc9bc1ab3478fbf81b5ae6c5fe1
CREATE OR REPLACE FUNCTION public.v2_meetings_list(p_school uuid, p_committee text, p_status text, p_days integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',m.id,'no',m.meeting_no,'kind',m.kind,'held_on',m.held_on,
      'started',m.started_at,'place',m.place_ar,'status',m.status,
      'committee',(select label_ar from v2.committees where key=m.committee_key),
      'agenda',m.agenda_ar,'quorum_met',m.quorum_met,
      'quorum_min', v2.quorum_of(m.school_id,m.committee_key),
      'items',(select count(*) from v2.meeting_items i where i.meeting_id=m.id),
      'invited',(select count(*) from v2.meeting_attendance a where a.meeting_id=m.id),
      'present',(select count(*) from v2.meeting_attendance a
                  where a.meeting_id=m.id and a.state='حاضر'),
      'called_by',(select v2.fn_display_name(full_name) from v2.people where id=m.called_by),
      'approved_by',(select v2.fn_display_name(full_name) from v2.people where id=m.approved_by)
    ) order by m.held_on desc nulls last, m.meeting_no desc),'[]'::jsonb)
  into r from v2.committee_meetings m
  where m.school_id=p_school
    and (p_committee is null or m.committee_key=p_committee)
    and (p_status    is null or m.status=p_status)
    and (p_days      is null or m.held_on >= current_date - p_days);
  return r;
end $function$
;
