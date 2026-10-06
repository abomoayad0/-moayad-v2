-- public.v2_meeting_approve(p_meeting uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e38674b1ce14f438d53a87b50db7e52f
CREATE OR REPLACE FUNCTION public.v2_meeting_approve(p_meeting uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare mt record; seat text; orphan int;
begin
  select * into mt from v2.committee_meetings where id=p_meeting;
  if mt.id is null then raise exception 'الاجتماعُ غيرُ موجود'; end if;
  if mt.status <> 'موثّق' then raise exception 'لا يُعتمد محضرٌ لم يُوثَّق بعد'; end if;
  seat := v2.my_seat(mt.school_id,mt.committee_key);
  if seat is distinct from 'chair' then
    raise exception 'اعتمادُ المحضر لرئيس اللجنة'; end if;

  -- 🔑 كلُّ قرارٍ أُقرّ يلزمه منفِّذٌ وموعد — وإلا سقط بالنسيان
  select count(*) into orphan from v2.meeting_items
   where meeting_id=p_meeting and outcome='أُقرّ'
     and (owner_person is null or due_on is null);
  if orphan > 0 then
    raise exception 'بقي % قرارًا بلا منفِّذٍ أو بلا موعد — ولا يصل قرارٌ لا صاحبَ له', orphan;
  end if;

  update v2.committee_meetings
     set status='معتمد', approved_by=v2.current_person(), approved_at=now()
   where id=p_meeting;
  return jsonb_build_object('ok',true,
    'tasks',(select count(*) from v2.meeting_items
              where meeting_id=p_meeting and outcome='أُقرّ'));
end $function$
;
