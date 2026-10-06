-- public.v2_committees_list(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cd81d61bbfd6c38ff5f4b82cc647617d
CREATE OR REPLACE FUNCTION public.v2_committees_list(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'key',c.key,'label',c.label_ar,'purpose',c.purpose,'source',c.source_page,
      'mine',(c.school_id is not null),'active',c.is_active,
      'members',(select count(*) from v2.committee_members m
                  where m.committee_key=c.key and m.school_id=p_school and m.ended_on is null),
      'duties',(select count(*) from v2.committee_duties d
                 where d.committee_key=c.key and d.is_active
                   and (d.school_id is null or d.school_id=p_school)),
      'meetings',(select count(*) from v2.committee_meetings mm
                   where mm.committee_key=c.key and mm.school_id=p_school),
      'open_tasks',(select count(*) from v2.meeting_items i
                     join v2.committee_meetings mm on mm.id=i.meeting_id
                    where mm.committee_key=c.key and mm.school_id=p_school
                      and mm.status='معتمد' and i.outcome='أُقرّ' and i.done_at is null))
      order by (c.school_id is not null), c.key),'[]'::jsonb)
  into r from v2.committees c
  where c.is_active and (c.school_id is null or c.school_id=p_school);
  return r;
end $function$
;
