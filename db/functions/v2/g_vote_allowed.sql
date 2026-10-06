-- v2.g_vote_allowed()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9a9fb6c5f9347e0985cc0bb4d91abd24
CREATE OR REPLACE FUNCTION v2.g_vote_allowed()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare a record; m uuid;
begin
  select mi.meeting_id into m from v2.meeting_items mi where mi.id = new.item_id;
  select * into a from v2.meeting_attendance
   where meeting_id = m and person_id = new.person_id;
  if a is null then
    raise exception 'لا يصوّت من لم يُسجَّل في حضور الاجتماع';
  end if;
  if a.invited_as = 'مستدعى' or a.can_vote = false then
    raise exception 'من يُستدعى من غير الأعضاء يشارك دون التصويت — الدليل التنظيمي ص١٩';
  end if;
  if a.state <> 'حاضر' then
    raise exception 'لا يصوّت غائبٌ ولا معتذر';
  end if;
  return new;
end $function$
;
