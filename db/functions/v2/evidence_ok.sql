-- v2.evidence_ok(p_entry uuid, p_path text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9c313dc1f657a9ab404b56889124fa0a
CREATE OR REPLACE FUNCTION v2.evidence_ok(p_entry uuid, p_path text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare pre text; obj record;
begin
  pre := v2.evidence_path_for(p_entry);
  if pre is null then return false; end if;
  if p_path not like pre||'%' then return false; end if;
  select * into obj from storage.objects
   where bucket_id='v2-attachments' and name=p_path;
  if obj.name is null then return false; end if;
  return true;
end $function$
;
