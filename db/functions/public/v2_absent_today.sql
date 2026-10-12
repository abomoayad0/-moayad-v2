-- public.v2_absent_today(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 56376c26e0a9042fd46786ba64d32596
CREATE OR REPLACE FUNCTION public.v2_absent_today(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("المنسوب" text, "السبب" text, "من حصّة" smallint, "إلى حصّة" smallint, "حصصُه اليوم" integer, "البيان" text, person_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select v2.fn_display_name(pe.full_name), r.label_ar, sa.from_period, sa.to_period,
    (select count(*) from v2.timetable t
      where t.school_id = p_school and t.person_id = sa.person_id
        and t.weekday = extract(dow from p_date)::smallint
        and t.slot_kind in ('teaching','activity')
        and (sa.from_period is null or t.period_no >= sa.from_period)
        and (sa.to_period   is null or t.period_no <= sa.to_period))::int,
    sa.note_ar, sa.person_id
  from v2.staff_absences sa
  join v2.people pe on pe.id = sa.person_id
  join v2.staff_absence_reasons r on r.key = sa.reason_key
  where sa.school_id = p_school and sa.on_date = p_date and sa.voided_at is null
    and v2.my_school(p_school)
  order by r.ord, pe.full_name
$function$
;
