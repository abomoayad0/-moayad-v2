-- v2.fn_add_working_days(p_school uuid, p_from date, p_days integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 34e1032a22d0347038fb902c9623faef
CREATE OR REPLACE FUNCTION v2.fn_add_working_days(p_school uuid, p_from date, p_days integer)
 RETURNS date
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
declare d date := p_from; n int := 0; k text;
begin
  while n < p_days loop
    d := d + 1;
    k := v2.fn_day_kind(p_school, d);
    if k is null then return null; end if;      -- خارج التقويم المنزَّل
    if k in ('study','exam') then n := n + 1; end if;
  end loop;
  return d;
end $function$
;
