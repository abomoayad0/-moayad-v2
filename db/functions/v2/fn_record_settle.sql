-- v2.fn_record_settle(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 dafad58f17f6610aa0e71920e4a6ae27
CREATE OR REPLACE FUNCTION v2.fn_record_settle(p_record uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare v_cur text; v_open int; v_total int;
begin
  select status into v_cur from v2.behavior_records where id = p_record;
  if v_cur is null or v_cur = 'voided' then return v_cur; end if;

  select count(*) filter (where t.status = 'open'), count(*)
    into v_open, v_total
  from v2.behavior_tasks t where t.record_id = p_record;

  -- 🔑 رصدةٌ بلا بندٍ واحدٍ لا تُستوفى — لئلّا تُقفل رصدةٌ لم ينظر فيها بشر
  if v_total = 0 then
    if v_cur <> 'open' then
      update v2.behavior_records set status='open', closed_at=null where id=p_record;
    end if;
    return 'open';
  end if;

  if v_open = 0 and v_cur = 'open' then
    update v2.behavior_records set status='closed', closed_at=now() where id=p_record;
    return 'closed';
  elsif v_open > 0 and v_cur = 'closed' then
    update v2.behavior_records set status='open', closed_at=null where id=p_record;
    return 'open';
  end if;

  return v_cur;
end
$function$
;
