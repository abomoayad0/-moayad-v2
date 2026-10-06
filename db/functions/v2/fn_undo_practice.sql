-- v2.fn_undo_practice(p_record uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 df17c2a6d6ceb4c41439e21ed9a18c61
CREATE OR REPLACE FUNCTION v2.fn_undo_practice(p_record uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if btrim(coalesce(p_reason,''))='' then raise exception 'لا تُلغى ممارسة بلا سبب مكتوب'; end if;
  update v2.practice_records set undone_at=now(), undo_reason=p_reason where id=p_record;
  delete from v2.practice_points where record_id=p_record;
end $function$
;
