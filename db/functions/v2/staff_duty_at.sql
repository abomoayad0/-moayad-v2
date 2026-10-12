-- v2.staff_duty_at(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1c0b9590368a0723dc0069029a70dabf
CREATE OR REPLACE FUNCTION v2.staff_duty_at(p_school uuid)
 RETURNS time without time zone
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t time;
begin
  select d.period1_at into t from v2.day_settings d where d.school_id = p_school;
  if t is null then
    raise exception 'لم يُضبط وقتُ الدوام الرسميّ لهذي المدرسة — ابنِ اليومَ الدراسيَّ أوّلًا';
  end if;
  return t;
end $function$
;
