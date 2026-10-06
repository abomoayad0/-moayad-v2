-- v2.g_meeting_flow()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4cd3442a75a237b87897bbbf65a786fa
CREATE OR REPLACE FUNCTION v2.g_meeting_flow()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare chair uuid; rap uuid; present int; need int;
begin
  select person_id into chair from v2.committee_members
   where committee_key = new.committee_key and seat_role = 'chair'
     and school_id = new.school_id and ended_on is null limit 1;
  select person_id into rap from v2.committee_members
   where committee_key = new.committee_key and seat_role = 'rapporteur'
     and school_id = new.school_id and ended_on is null limit 1;

  if new.called_by is not null and chair is not null and new.called_by <> chair then
    raise exception 'الدعوةُ لاجتماع اللجنة من رئيسها وحدَه — الدليل التنظيميّ ص١٩'; end if;
  if new.minutes_by is not null and rap is not null and new.minutes_by <> rap then
    raise exception 'المحضرُ يكتبه مقرّرُ اللجنة'; end if;
  if new.approved_by is not null and chair is not null and new.approved_by <> chair then
    raise exception 'اعتمادُ المحضر لرئيس اللجنة'; end if;

  if new.status in ('موثّق','معتمد') then
    select count(*) into present from v2.meeting_attendance
     where meeting_id = new.id and state = 'حاضر' and can_vote;
    need := coalesce(v2.quorum_of(new.school_id,new.committee_key),0);
    new.quorum_met := (need = 0) or (present >= need);
    if new.status = 'معتمد' and new.quorum_met = false then
      raise exception 'لا يُعتمد محضرٌ لم يكتمل نصابُه (الحاضرون %, المطلوب %)', present, need;
    end if;
  end if;
  return new;
end $function$
;
