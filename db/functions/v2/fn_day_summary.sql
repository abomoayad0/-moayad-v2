-- v2.fn_day_summary(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 89136f054d60f0eb890ab1e2d4a753e0
CREATE OR REPLACE FUNCTION v2.fn_day_summary(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS TABLE("نوع_اليوم" text, "هجري" text, "المقيدون" integer, "حاضر" integer, "غياب" integer, "تأخر" integer, "استئذان" integer, "لم_يُرصد" integer, "تخلف_عن_الاصطفاف" integer, "مقفل" boolean, "أُعيد_فتحه" boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
with l as (select * from v2.fn_day_list(p_school,p_date))
select coalesce(v2.fn_day_kind(p_school,p_date),'غير معروف'), v2.fn_to_hijri(p_date),
 count(*)::int,
 count(*) filter (where state='present')::int,
 count(*) filter (where state='absent')::int,
 count(*) filter (where state='late')::int,
 count(*) filter (where state='permitted')::int,
 count(*) filter (where state='unrecorded')::int,
 count(*) filter (where assembly_state in ('missed_inside','late_inside'))::int,
 exists (select 1 from v2.day_closures c where c.school_id=p_school and c.on_date=p_date and c.reopened_at is null),
 exists (select 1 from v2.day_closures c where c.school_id=p_school and c.on_date=p_date and c.reopened_at is not null)
from l;
$function$
;
