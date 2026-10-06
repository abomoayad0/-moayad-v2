-- v2.trg_tt_period()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c50f6dbcef9d90973de0e97e9413433e
CREATE OR REPLACE FUNCTION v2.trg_tt_period()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if not exists (select 1 from v2.period_slots p where p.school_id=new.school_id and p.period_no=new.period_no) then
    raise exception 'الحصة % غير معرّفة في حصص اليوم لهذه المدرسة', new.period_no; end if;
  return new;
end $function$
;
