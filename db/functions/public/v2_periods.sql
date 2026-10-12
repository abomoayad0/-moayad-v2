-- public.v2_periods(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c763c19f018c166a1cb69c8e0a413a53
CREATE OR REPLACE FUNCTION public.v2_periods(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception '%', v2.not_my_school_ar(); end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'no',s.period_no,'no_ar',v2.ar_num(s.period_no),
      'label', case when s.label_ar is null or s.label_ar ~ '[0-9]'
                    then 'الحصة '||v2.ar_num(s.period_no) else s.label_ar end,
      'starts',s.starts_at,'ends',s.ends_at) order by s.period_no),'[]'::jsonb)
  into r from v2.period_slots s where s.school_id=p_school;
  return r;
end $function$
;
