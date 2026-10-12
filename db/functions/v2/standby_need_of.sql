-- v2.standby_need_of(p_school uuid, p_weekday smallint, p_period smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 afa3dcb225f453c06c17b86d42a7a0f7
CREATE OR REPLACE FUNCTION v2.standby_need_of(p_school uuid, p_weekday smallint, p_period smallint)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce((
    select n.need from v2.standby_need n
     where n.school_id = p_school
       and (n.weekday is null or n.weekday = p_weekday)
       and (n.period_no is null or n.period_no = p_period)
     order by (case when n.weekday is not null then 1 else 0 end)
            + (case when n.period_no is not null then 1 else 0 end) desc
     limit 1), 1::smallint);
$function$
;
