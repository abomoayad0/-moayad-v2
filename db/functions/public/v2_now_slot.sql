-- public.v2_now_slot(p_school uuid, p_at time without time zone)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8ed410ca5acef988d5a454725da737a1
CREATE OR REPLACE FUNCTION public.v2_now_slot(p_school uuid, p_at time without time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t time; b record; s record;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  t := coalesce(p_at, (now() at time zone 'Asia/Riyadh')::time);
  select * into b from v2.break_slots
   where school_id=p_school and active and t between starts_at and ends_at limit 1;
  if b.id is not null then
    return jsonb_build_object('kind','break','break_kind',b.kind,'label',b.label_ar,
      'starts_ar',v2.time_ar(b.starts_at),'ends_ar',v2.time_ar(b.ends_at),
      'place_hint', b.label_ar, 'at_ar', v2.time_ar(t));
  end if;
  select * into s from v2.period_slots
   where school_id=p_school and t between starts_at and ends_at limit 1;
  if s.period_no is not null then
    return jsonb_build_object('kind','period','period_no',s.period_no,
      'period_ar',v2.ar_num(s.period_no),
      'label', case when s.label_ar ~ '[0-9]' or s.label_ar is null
                    then 'الحصة '||v2.ar_num(s.period_no) else s.label_ar end,
      'starts_ar',v2.time_ar(s.starts_at),'ends_ar',v2.time_ar(s.ends_at),
      'place_hint','الفصل','at_ar', v2.time_ar(t));
  end if;
  return jsonb_build_object('kind','outside','label','خارج اليوم الدراسيّ',
    'at_ar', v2.time_ar(t));
end $function$
;
