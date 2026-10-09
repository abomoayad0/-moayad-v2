-- public.v2_meeting_card(p_meeting uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3fca22ef943f8c5749048d447976edc7
CREATE OR REPLACE FUNCTION public.v2_meeting_card(p_meeting uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; vt int;
begin
  select count(*) into vt from v2.meeting_attendance
   where meeting_id=p_meeting and state='حاضر' and can_vote;

  select jsonb_build_object(
    'meeting', (to_jsonb(m) - 'school_id')
      || jsonb_build_object(
         'minutes_by_name',(select v2.fn_display_name(full_name) from v2.people where id=m.minutes_by),
         'approved_by_name',(select v2.fn_display_name(full_name) from v2.people where id=m.approved_by),
         'called_by_name',(select v2.fn_display_name(full_name) from v2.people where id=m.called_by),
         'quorum_min', v2.quorum_of(m.school_id,m.committee_key)),
    'committee',(select label_ar from v2.committees where key=m.committee_key),
    'voters_total', vt,
    'attendance',(select jsonb_agg(jsonb_build_object(
        'person_id', a.person_id,
        'student_id', a.guest_student_id,
        'guardian_id', a.guest_guardian_id,
        'name',coalesce(v2.fn_display_name(pe.full_name), a.guest_name),
        'who', a.guest_kind,
        'seat',a.seat_role,'seat_ar',v2.seat_ar(a.seat_role),
        'as',a.invited_as,'vote_right',a.can_vote,
        'no_vote_reason', case when not a.can_vote
          then 'يشارك في المناقشة ولا يصوّت على قرارات اللجنة — '||v2.cite_page('committee.meetings')||'' end,
        'state',a.state,'excuse',a.excuse_ar)
        order by a.invited_as, a.seat_role)
      from v2.meeting_attendance a left join v2.people pe on pe.id=a.person_id
      where a.meeting_id=m.id),
    'items',(select jsonb_agg(jsonb_build_object(
        'id',i.id,'ord',i.ord,'kind',i.subject_kind,'title',i.title_ar,
        'student_id', i.student_id,
        'student_name',(select v2.fn_display_name(s.full_name) from v2.students s where s.id=i.student_id),
        'record_id', i.record_id, 'opp_id', i.opp_ref,
        'body',i.body_ar,'decision',i.decision_ar,'recommend',i.recommend_ar,
        'owner_id', i.owner_person,
        'owner_name',(select v2.fn_display_name(full_name) from v2.people where id=i.owner_person),
        'outcome',i.outcome,'due',i.due_on,
        'vote_count',(select count(*) from v2.meeting_votes v where v.item_id=i.id),
        'voters_total', vt,
        'tally',(select jsonb_build_object(
             'موافق',count(*) filter (where vote='موافق'),
             'مخالف',count(*) filter (where vote='مخالف'),
             'ممتنع',count(*) filter (where vote='ممتنع'))
           from v2.meeting_votes v where v.item_id=i.id),
        'votes',(select coalesce(jsonb_agg(jsonb_build_object(
             'person_id',v.person_id,
             'name',v2.fn_display_name(p2.full_name),'vote',v.vote,'note',v.note_ar,
             'prev_vote',v.prev_vote,'change_note',v.change_note,'changed_at',v.changed_at)),'[]'::jsonb)
           from v2.meeting_votes v join v2.people p2 on p2.id=v.person_id
           where v.item_id=i.id)) order by i.ord)
      from v2.meeting_items i where i.meeting_id=m.id)
  ) into r from v2.committee_meetings m where m.id=p_meeting;
  return r;
end $function$
;
