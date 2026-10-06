-- v2.trg_attendance_calendar_guard()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 14d6360a4ac17a24c3e9e57abc335de6
CREATE OR REPLACE FUNCTION v2.trg_attendance_calendar_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare k text;
begin
  k := v2.fn_day_kind(new.school_id, new.on_date);
  if k is null then
    raise exception 'اليوم % خارج التقويم الدراسي المنزَّل لهذه المدرسة — لا يُرصد', new.on_date;
  end if;
  if k not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة: %. ولا يُرصد فيه حضور ولا غياب', new.on_date,
      case k when 'holiday' then 'إجازة' when 'weekend' then 'عطلة نهاية الأسبوع'
             when 'suspended' then 'دراسة معلّقة' else k end;
  end if;
  return new;
end $function$
;
