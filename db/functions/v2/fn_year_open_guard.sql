-- v2.fn_year_open_guard()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 44e60f9b69b345923b7192a7021d44e1
CREATE OR REPLACE FUNCTION v2.fn_year_open_guard()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare v_status text;
begin
  select status into v_status from v2.academic_years where id = new.year_id;
  if v_status = 'closed' then
    raise exception 'السنة الدراسية مغلقة: لا يُكتب فيها ولا يُعدَّل. افتح سنةً جديدة.';
  end if;
  return new;
end $function$
;
