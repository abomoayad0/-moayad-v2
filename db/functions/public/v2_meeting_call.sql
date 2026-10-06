-- public.v2_meeting_call(p_school uuid, p_committee text, p_kind text, p_held_on date, p_started time without time zone, p_place text, p_agenda text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1f87311b19823ae194284973f24e6644
CREATE OR REPLACE FUNCTION public.v2_meeting_call(p_school uuid, p_committee text, p_kind text, p_held_on date, p_started time without time zone, p_place text, p_agenda text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid; seat text; nid uuid; n smallint;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  me := v2.current_person();
  seat := v2.my_seat(p_school,p_committee);
  if seat is distinct from 'chair' then
    raise exception 'الدعوةُ لاجتماع اللجنة من رئيسها وحدَه — الدليل التنظيميّ ص١٩'; end if;
  if coalesce(p_kind,'شهري') not in ('شهري','طارئ') then
    raise exception 'الاجتماعُ شهريٌّ أو طارئ'; end if;
  if p_held_on < current_date then
    raise exception 'لا يُدعى إلى اجتماعٍ في تاريخٍ مضى'; end if;
  if btrim(coalesce(p_agenda,''))='' then
    raise exception 'لا دعوةَ بلا جدول أعمال'; end if;

  select coalesce(max(meeting_no),0)+1 into n from v2.committee_meetings
   where school_id=p_school and committee_key=p_committee;

  insert into v2.committee_meetings(school_id,committee_key,kind,meeting_no,
     held_on,started_at,place_ar,called_by,called_at,agenda_ar,status)
  values (p_school,p_committee,coalesce(p_kind,'شهري'),n,p_held_on,p_started,
     nullif(btrim(coalesce(p_place,'')),''),me,now(),p_agenda,'مدعوّ إليه')
  returning id into nid;

  -- 🔑 يُدعون — ولا يُعدّون حاضرين حتى يُسجَّل حضورُهم
  insert into v2.meeting_attendance(meeting_id,person_id,seat_role,invited_as,can_vote,state)
  select nid, m.person_id, m.seat_role, 'عضو', true, 'مدعوّ'
    from v2.committee_members m
   where m.committee_key=p_committee and m.school_id=p_school and m.ended_on is null;

  return jsonb_build_object('ok',true,'meeting',nid,'no',n,
    'invited',(select count(*) from v2.meeting_attendance where meeting_id=nid),
    'present',0);
end $function$
;
