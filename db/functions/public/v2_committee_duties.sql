-- public.v2_committee_duties(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9adda26fe3429b297f9b6e936379ab7d
CREATE OR REPLACE FUNCTION public.v2_committee_duties(p_school uuid, p_committee text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',d.id,'ord',d.ord,'text',d.text_ar,'cadence',d.cadence,
      'source',d.source_ar,'mine',(d.school_id is not null),
      -- 🔑 ربطٌ حقيقيٌّ بالبند
      'items',(select count(*) from v2.meeting_items i
                join v2.committee_meetings m on m.id=i.meeting_id
               where i.duty_id=d.id and m.school_id=p_school),
      'last_done',(select max(m.held_on) from v2.meeting_items i
                join v2.committee_meetings m on m.id=i.meeting_id
               where i.duty_id=d.id and m.school_id=p_school and m.status='معتمد'))
      order by d.ord, d.text_ar),'[]'::jsonb)
  into r from v2.committee_duties d
  where d.committee_key=p_committee and d.is_active
    and (d.school_id is null or d.school_id=p_school);
  return r;
end $function$
;
