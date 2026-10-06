-- public.v2_error_fixed(p_id uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 93355da25de80dacb8642911323c48d3
CREATE OR REPLACE FUNCTION public.v2_error_fixed(p_id uuid, p_note text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if (v2.my_grant() is null or v2.my_grant() not in ('owner','admin')) then raise exception 'للمالك وحده'; end if;
  update v2.error_log set fixed=true, seen=true, fix_note=p_note where id=p_id;
end $function$
;
