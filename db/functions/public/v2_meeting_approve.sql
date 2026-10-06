-- public.v2_meeting_approve(p_meeting uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 196d80a1f5116e8a7aff477ca0dd7da8
CREATE OR REPLACE FUNCTION public.v2_meeting_approve(p_meeting uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text;
begin
  select * into mt from v2.committee_meetings where id=p_meeting;
  if mt is null then raise exception 'الاجتماعُ غيرُ موجود'; end if;
  if mt.status <> 'موثّق' then
    raise exception 'لا يُعتمد محضرٌ لم يُوثَّق بعد';
  end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat is distinct from 'chair' then
    raise exception 'اعتمادُ المحضر لرئيس اللجنة';
  end if;
  update v2.committee_meetings
     set status='معتمد', approved_by=v2.current_person(), approved_at=now()
   where id=p_meeting;
  return jsonb_build_object('ok',true);
end $function$
;
