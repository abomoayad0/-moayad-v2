-- v2.trg_period_guard()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 51053c54d84a58b40dab60009bc02dcb
CREATE OR REPLACE FUNCTION v2.trg_period_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare k text;
begin
  k := v2.fn_day_kind(new.school_id, new.on_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة — لا تُرصد فيه حصص', new.on_date;
  end if;
  return new;
end $function$
;
