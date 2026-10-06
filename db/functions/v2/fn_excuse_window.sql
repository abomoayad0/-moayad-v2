-- v2.fn_excuse_window(p_school uuid, p_absence date, p_submitted date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 07218eea925f9c93c327b949df1ed339
CREATE OR REPLACE FUNCTION v2.fn_excuse_window(p_school uuid, p_absence date, p_submitted date)
 RETURNS TABLE("أيام_العمل_المستغرقة" integer, "حدّ_الثلاثة" date, "حدّ_العشرة" date, "الحكم" text)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with w as (
  select v2.fn_add_working_days(p_school,p_absence,3) w3,
         v2.fn_add_working_days(p_school,p_absence,10) w10,
         (select count(*)::int from v2.calendar_days d
           join v2.calendar_years y on y.id=d.year_id
           join v2.schools s on s.calendar_scope=y.scope_key
          where s.id=p_school and d.on_g > p_absence and d.on_g <= p_submitted
            and d.day_kind in ('study','exam')) used
)
select used, w3, w10,
  case
    when w3 is null then 'خارج التقويم المنزَّل — لا يُحكم'
    when p_submitted <= w3 then 'داخل المهلة النظامية (ثلاثة أيام عمل) — يُقبل ولا يؤثر على درجة المواظبة · م31 بند 6 وم35 بند 7'
    when p_submitted <= w10 then 'بعد المهلة ودون العشرة — يجوز قبوله بمبرر مقبول · م31 بند 6'
    else 'تجاوز عشرة أيام عمل — لا يُقبل إلا بتمديد من مدير المدرسة حتى نهاية الفصل مع إرفاق ما يدعم القرار في نور · م31 بند 6'
  end
from w;
$function$
;
