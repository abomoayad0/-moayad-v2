-- v2.swap_matches(p_my_slot uuid, p_on date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d482f120ff6f87c1fd9db11a896a756f
CREATE OR REPLACE FUNCTION v2.swap_matches(p_my_slot uuid, p_on date)
 RETURNS TABLE(slot uuid, period_no smallint, section_ar text, subject_ar text, person_id uuid, person_ar text, why_ar text, ok boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with me as (select t.* from v2.timetable t where t.id = p_my_slot),
  wd as (select extract(dow from p_on)::smallint d),
  ev as (
    select s.id sid, s.period_no pn, s.section_id secid, s.subject_ar subj, s.person_id tid,
      exists (select 1 from v2.timetable x, me, wd
               where x.school_id = me.school_id and x.person_id = s.person_id
                 and x.weekday = wd.d and x.period_no = me.period_no
                 and x.slot_kind in ('teaching','activity') and x.id <> s.id) busy_him,
      exists (select 1 from v2.timetable y, me, wd
               where y.school_id = me.school_id and y.person_id = me.person_id
                 and y.weekday = wd.d and y.period_no = s.period_no
                 and y.slot_kind in ('teaching','activity') and y.id <> p_my_slot) busy_me,
      exists (select 1 from v2.staff_absences a, me
               where a.school_id = me.school_id and a.person_id = s.person_id
                 and a.on_date = p_on and a.voided_at is null) away,
      exists (select 1 from v2.period_swaps w, me
               where w.school_id = me.school_id and w.on_date = p_on
                 and w.status in ('pending','partner_ok','done')
                 and (w.req_slot = s.id or w.partner_slot = s.id)) taken
    from v2.timetable s, me, wd
   where s.school_id = me.school_id and s.weekday = wd.d
     and s.slot_kind in ('teaching','activity')
     and s.person_id is not null and s.person_id <> me.person_id
     and s.period_no <> me.period_no
  )
  select ev.sid, ev.pn,
    coalesce((select cs.label_ar from v2.class_sections cs where cs.id=ev.secid),'—'),
    ev.subj, ev.tid, v2.fn_display_name(pe.full_name),
    case when ev.busy_him then 'مشغولٌ في وقت حصّتك'
         when ev.busy_me  then 'أنت مشغولٌ في وقت حصّته'
         when ev.away     then 'غائبٌ ذلك اليوم'
         when ev.taken    then 'حصّتُه مبدَّلةٌ ذلك اليوم'
         else 'متاح' end,
    not (ev.busy_him or ev.busy_me or ev.away or ev.taken)
  from ev join v2.people pe on pe.id = ev.tid
  order by (ev.busy_him or ev.busy_me or ev.away or ev.taken), ev.pn
$function$
;
