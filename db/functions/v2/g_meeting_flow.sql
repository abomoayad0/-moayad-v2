-- v2.g_meeting_flow()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3833b997670c21a4189d392013707a82
CREATE OR REPLACE FUNCTION v2.g_meeting_flow()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare chair uuid; rap uuid; repl int; need int;
begin
  select person_id into chair from v2.committee_members
   where committee_key = new.committee_key and seat_role = 'chair'
     and school_id = new.school_id and ended_on is null limit 1;
  select person_id into rap from v2.committee_members
   where committee_key = new.committee_key and seat_role = 'rapporteur'
     and school_id = new.school_id and ended_on is null limit 1;

  if new.called_by is not null and chair is not null and new.called_by <> chair then
    raise exception '%', 'الدعوةُ لاجتماع اللجنة من رئيسها وحدَه — الدليل التنظيمي '||v2.cite_page('committee.meetings')||''; end if;
  if new.minutes_by is not null and rap is not null and new.minutes_by <> rap then
    raise exception 'المحضرُ يكتبه مقرّرُ اللجنة'; end if;
  if new.approved_by is not null and chair is not null and new.approved_by <> chair then
    raise exception 'اعتمادُ المحضر لرئيس اللجنة'; end if;

  if new.status in ('موثّق','معتمد') then
    select count(*) into repl from v2.meeting_attendance
     where meeting_id = new.id and state in ('حاضر','عن بُعد') and can_vote;
    need := coalesce((v2.committee_rule(new.school_id,new.committee_key)->>'quorum_min')::int, 0);
    new.quorum_met := (need = 0) or (repl >= need);
    if new.status = 'معتمد' and new.quorum_met = false then
      raise exception 'لا يُعتمد محضرٌ لم يكتمل نصابُه (ردّ %, والمطلوب %)', repl, need;
    end if;
  end if;
  return new;
end $function$
;
