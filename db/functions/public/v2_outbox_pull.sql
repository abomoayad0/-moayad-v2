-- public.v2_outbox_pull(p_limit integer)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 feea9f3e207171d8d98da3241a2f3580
CREATE OR REPLACE FUNCTION public.v2_outbox_pull(p_limit integer DEFAULT 50)
 RETURNS TABLE(id uuid, channel text, to_phone text, to_name text, body_ar text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if not v2.leads_school(array['deputy','deputy_students','deputy_school','deputy_school_students']) then
    raise exception 'سحبُ طابور الإرسال للمالك ولإدارة المدرسة بتكليفها';
  end if;
  return query
   update v2.outbox o set status='sent', attempts=o.attempts+1, sent_at=now()
    where o.id in (select x.id from v2.outbox x where x.status='queued' order by x.queued_at limit p_limit)
   returning o.id, o.channel, o.to_phone, o.to_name, o.body_ar;
end $function$
;
