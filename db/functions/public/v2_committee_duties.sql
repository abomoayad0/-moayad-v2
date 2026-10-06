-- public.v2_committee_duties(p_school uuid, p_committee text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 28e003e15316806a3918d6a0dff30efd
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
      'done_this_term',(select count(*) from v2.meeting_items i
         join v2.committee_meetings m on m.id=i.meeting_id
        where m.committee_key=p_committee and m.school_id=p_school
          and m.status='معتمد' and i.title_ar ilike '%'||left(d.text_ar,20)||'%'))
      order by d.ord, d.text_ar),'[]'::jsonb)
  into r from v2.committee_duties d
  where d.committee_key=p_committee and d.is_active
    and (d.school_id is null or d.school_id=p_school);
  return r;
end $function$
;
