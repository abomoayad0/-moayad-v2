-- public.v2_breaks(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 31e6eacd02496509b22af14f16cc1194
CREATE OR REPLACE FUNCTION public.v2_breaks(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',b.id,'kind',b.kind,'label',b.label_ar,
      'starts',b.starts_at,'starts_ar',v2.time_ar(b.starts_at),
      'ends',b.ends_at,'ends_ar',v2.time_ar(b.ends_at),
      'minutes',(extract(epoch from (b.ends_at-b.starts_at))/60)::int,
      'minutes_ar',v2.ar_num((extract(epoch from (b.ends_at-b.starts_at))/60)::int),
      'after_period',b.after_period,
      'after_period_ar', case when b.after_period is null then null
                              else 'بعد الحصّة '||v2.ar_num(b.after_period) end,
      'needs_duty',b.needs_duty,'min_staff',b.min_staff,'note',b.note_ar,
      'duty_now',(select count(*) from v2.duty_roster d
                   where d.school_id=p_school and d.break_id=b.id))
      order by b.starts_at),'[]'::jsonb)
  into r from v2.break_slots b where b.school_id=p_school and b.active;
  return r;
end $function$
;
