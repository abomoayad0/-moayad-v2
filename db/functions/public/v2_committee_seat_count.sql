-- public.v2_committee_seat_count(p_school uuid, p_committee text, p_seat_role text, p_count smallint, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f3e349fa56058ff7018b3af769b8d375
CREATE OR REPLACE FUNCTION public.v2_committee_seat_count(p_school uuid, p_committee text, p_seat_role text, p_count smallint, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare s record; seated int;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'تعديل سعة مقعد');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into s from v2.committee_seats
   where committee_key=p_committee and seat_role=p_seat_role and post_key is null limit 1;
  if s.committee_key is null then
    raise exception 'لا يُعدَّل إلا المقعدُ المنتخَب — أمّا مقعدُ الوظيفة فنصُّ الدليل'; end if;
  if p_count < 1 then raise exception 'السعةُ واحدٌ فأكثر'; end if;
  if btrim(coalesce(p_reason,''))='' then raise exception 'لا تُغيَّر سعةُ مقعدٍ بلا سببٍ مكتوب'; end if;
  select count(*) into seated from v2.committee_members
   where committee_key=p_committee and school_id=p_school
     and seat_role=p_seat_role and via_post_key is null and ended_on is null;
  if p_count < seated then
    raise exception 'يجلس في هذا المقعد % في هذي المدرسة — أخرِجْهم قبل تضييق السعة', seated; end if;

  insert into v2.committee_school_rules(school_id,committee_key,seat_role,seat_count,reason_ar,set_by)
  values (p_school,p_committee,p_seat_role,p_count,
    'الدليلُ التنظيميُّ: '||s.seat_count||' · وقرارُ المدرسة: '||p_count||' — '||btrim(p_reason),
    v2.current_person())
  on conflict (school_id,committee_key,seat_role) do update
    set seat_count=excluded.seat_count, reason_ar=excluded.reason_ar,
        set_by=excluded.set_by, set_at=now();
  return jsonb_build_object('ok',true,'count',p_count,'seated',seated);
end $function$
;
