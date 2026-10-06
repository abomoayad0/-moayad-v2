-- v2.fn_duty_today(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c75614a6e8750b2963f413a7ef226d39
CREATE OR REPLACE FUNCTION v2.fn_duty_today(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE(zone_key text, zone_ar text, segment text, min_staff smallint, staff_n integer, staff_ar text, is_enough boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select z.key, z.label_ar, z.segment, z.min_staff,
 count(r.id)::int,
 coalesce(string_agg(v2.fn_display_name(p.full_name),' · '),'— لا أحد'),
 count(r.id) >= z.min_staff
from v2.duty_zones z
left join v2.duty_roster r on r.zone_id=z.id
  and r.weekday = extract(dow from p_date)::smallint
  and r.starts_on <= p_date and (r.ends_on is null or r.ends_on >= p_date)
left join v2.people p on p.id=r.person_id
where z.school_id=p_school and z.active
group by z.key, z.label_ar, z.segment, z.min_staff, z.id
order by case z.segment when 'assembly' then 1 when 'period' then 2 when 'break' then 3
  when 'prayer' then 4 when 'halls' then 5 when 'gate' then 6 else 7 end, z.label_ar
$function$
;
