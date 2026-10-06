-- public.v2_arrival_check(p_school uuid, p_at time without time zone)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 586306126b2d3858c1dbd0cd0f50e0d4
CREATE OR REPLACE FUNCTION public.v2_arrival_check(p_school uuid, p_at time without time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare d record; stt text; mins int;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into d from v2.day_settings where school_id=p_school;
  if d.school_id is null then
    raise exception 'لا توقيتاتِ يومٍ لمدرستك — أسّسها من لوحة التحكّم'; end if;
  stt  := v2.arrival_state(p_school, p_at);
  mins := case when p_at is null then null
            else greatest(0, (extract(epoch from (p_at - d.assembly_at))/60)::int
                             - coalesce(d.late_grace_min,0)) end;
  return jsonb_build_object(
    'state', stt,
    'state_ar', case stt when 'present' then 'حاضر'
                         when 'late' then 'متأخّر' else 'غائب' end,
    'at_ar', v2.time_ar(p_at),
    'minutes', mins, 'minutes_ar', v2.ar_num(mins),
    'assembly_at', d.assembly_at, 'assembly_ar', v2.time_ar(d.assembly_at),
    'grace_min', d.late_grace_min, 'grace_ar', v2.ar_num(d.late_grace_min),
    'late_cutoff_at', d.late_cutoff_at,
    'late_cutoff_ar', v2.time_ar(d.late_cutoff_at),
    'late_cutoff_note', d.late_cutoff_note,
    'can_record_arrival', (stt = 'late'),
    'why', case stt
      when 'absent' then 'وصل بعد حدّ التأخّر ('||coalesce(v2.time_ar(d.late_cutoff_at),'—')||
                         ') — فيُسجَّل غائبًا لا متأخّرًا'
      when 'late'   then 'وصل بعد الاصطفاف بـ'||v2.ar_num(mins)||' دقيقة'
      else 'وصل في وقته' end);
end $function$
;
