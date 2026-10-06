-- public.v2_committee_close(p_school uuid, p_committee text, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a349b1b060b6218aa37c65bfdb8f5d2c
CREATE OR REPLACE FUNCTION public.v2_committee_close(p_school uuid, p_committee text, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record;
begin
  perform v2.assert_role(array['principal'],'إيقافَ لجنة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into c from v2.committees where key=p_committee;
  if c.key is null then raise exception 'لجنةٌ غيرُ معروفة'; end if;
  if c.school_id is null then
    raise exception 'هذي لجنةٌ وزاريّةٌ بنصّ الدليل — لا تُوقف ولا تُحذف'; end if;
  if c.school_id <> p_school then raise exception 'ليست لجنةَ مدرستك'; end if;
  if btrim(coalesce(p_reason,''))='' then raise exception 'لا تُوقف لجنةٌ بلا سببٍ مكتوب'; end if;
  if exists (select 1 from v2.committee_meetings m
              where m.committee_key=p_committee and m.status in ('مدعوّ إليه','منعقد','موثّق')) then
    raise exception 'للجنة اجتماعٌ لم يُعتمد بعد — أغلقه أوّلًا'; end if;

  update v2.committees set is_active=false,
    purpose = coalesce(purpose,'')||' · أُوقفت '||current_date||': '||btrim(p_reason)
   where key=p_committee;
  update v2.committee_members set ended_on=current_date, end_reason='أُوقفت اللجنة'
   where committee_key=p_committee and school_id=p_school and ended_on is null;
  return jsonb_build_object('ok',true,'note','أُوقفت اللجنةُ — ومحاضرُها باقية');
end $function$
;
