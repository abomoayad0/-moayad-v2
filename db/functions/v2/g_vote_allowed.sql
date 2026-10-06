-- v2.g_vote_allowed()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 835106dc305364e75966f15af409fcd3
CREATE OR REPLACE FUNCTION v2.g_vote_allowed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare a record; m uuid;
begin
  select mi.meeting_id into m from v2.meeting_items mi where mi.id = new.item_id;
  select * into a from v2.meeting_attendance
   where meeting_id = m and person_id = new.person_id;
  if a is null then raise exception 'لا يصوّت من لم يُسجَّل في حضور الاجتماع'; end if;
  if a.invited_as = 'مستدعى' or a.can_vote = false then
    raise exception 'من يُستدعى من غير الأعضاء يشارك دون التصويت — الدليل التنظيمي ص١٩'; end if;
  if a.state not in ('حاضر','عن بُعد') then
    raise exception 'لا يصوّت غائبٌ ولا معتذر'; end if;
  return new;
end $function$
;
