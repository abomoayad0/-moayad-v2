-- public.v2_outbox_result(p_id uuid, p_ok boolean, p_ref text, p_err text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 54f4f8d8feaf296042fa296a3e46a2ca
CREATE OR REPLACE FUNCTION public.v2_outbox_result(p_id uuid, p_ok boolean, p_ref text DEFAULT NULL::text, p_err text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  update v2.outbox set status = case when p_ok then 'delivered' else 'failed' end,
    provider_ref=p_ref, last_error=p_err where id=p_id;
  update v2.event_deliveries d set status = case when p_ok then 'delivered' else 'failed' end,
    sent_at=now(), fail_reason=p_err
   from v2.outbox o where o.id=p_id and d.id=o.delivery_id;
end $function$
;
