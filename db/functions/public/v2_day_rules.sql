-- public.v2_day_rules(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5db94fdb1d5bcc1e3a5c4755063808e0
CREATE OR REPLACE FUNCTION public.v2_day_rules(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare d record;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into d from v2.day_settings where school_id=p_school;
  if d.school_id is null then
    raise exception 'لا توقيتاتِ يومٍ لمدرستك — أسّسها من لوحة التحكّم'; end if;
  return jsonb_build_object(
    'assembly_at', d.assembly_at, 'period1_at', d.period1_at,
    'period_minutes', d.period_minutes, 'grace_min', d.late_grace_min,
    'prenotice_after_min', d.prenotice_after_min, 'close_at', d.close_at,
    'late_cutoff_at', d.late_cutoff_at, 'late_cutoff_note', d.late_cutoff_note,
    'periods', (select coalesce(jsonb_agg(jsonb_build_object(
          'no',s.period_no,'no_ar',v2.ar_num(s.period_no),
          'starts',s.starts_at,'ends',s.ends_at) order by s.period_no),'[]'::jsonb)
        from v2.period_slots s where s.school_id=p_school));
end $function$
;
