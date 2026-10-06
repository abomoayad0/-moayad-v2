-- public.v2_meeting_minute(p_meeting uuid, p_ended time without time zone)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a96d1fbb455ed48f52d62a7079c47474
CREATE OR REPLACE FUNCTION public.v2_meeting_minute(p_meeting uuid, p_ended time without time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text; open_items int;
begin
  select * into mt from v2.committee_meetings where id=p_meeting;
  if mt is null then raise exception 'الاجتماعُ غيرُ موجود'; end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat is distinct from 'rapporteur' then
    raise exception 'المحضرُ يكتبه مقرّرُ اللجنة — ص١٩';
  end if;
  select count(*) into open_items from v2.meeting_items
   where meeting_id=p_meeting and outcome='قيد النظر';
  if open_items > 0 then
    raise exception 'بقي % بندًا لم يُقفل', open_items;
  end if;
  update v2.committee_meetings
     set status='موثّق', minutes_by=v2.current_person(), minutes_at=now(), ended_at=p_ended
   where id=p_meeting;
  return jsonb_build_object('ok',true,'quorum',(select quorum_met from v2.committee_meetings where id=p_meeting));
end $function$
;
