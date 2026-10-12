-- v2.remedial_day(p_school uuid, p_person uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f84c13f96b66bd756b68b6a02b6c78b1
CREATE OR REPLACE FUNCTION v2.remedial_day(p_school uuid, p_person uuid, p_date date)
 RETURNS TABLE(slot uuid, period_no smallint, subject_ar text, plan_id uuid, title_ar text, kind text, members_n integer, from_standby boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select t.id, t.period_no, t.subject_ar, p.id, p.title_ar, p.kind,
         case when p.kind='individual' then 1
              else (select count(*)::int from v2.remedial_members m
                     where m.plan_id=p.id and m.removed_at is null) end,
         rp.from_standby
    from v2.remedial_periods rp
    join v2.remedial_plans  p on p.id = rp.plan_id and p.voided_at is null
    join v2.timetable       t on t.id = rp.slot_id
   where rp.school_id = p_school and rp.person_id = p_person
     and rp.state = 'approved' and t.slot_kind = 'remedial'
     and t.weekday = extract(dow from p_date)::smallint
   order by t.period_no
$function$
;
