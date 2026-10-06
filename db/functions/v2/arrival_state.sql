-- v2.arrival_state(p_school uuid, p_at time without time zone)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 642941a33a8d4e48599fda6e748fa007
CREATE OR REPLACE FUNCTION v2.arrival_state(p_school uuid, p_at time without time zone)
 RETURNS text
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select case
    when p_at is null then 'present'
    when exists (select 1 from v2.day_settings d
                  where d.school_id=p_school and d.late_cutoff_at is not null
                    and p_at > d.late_cutoff_at) then 'absent'
    when exists (select 1 from v2.day_settings d
                  where d.school_id=p_school
                    and p_at > (d.assembly_at + (coalesce(d.late_grace_min,0)||' minutes')::interval)::time)
      then 'late'
    else 'present' end;
$function$
;
