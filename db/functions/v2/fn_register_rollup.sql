-- v2.fn_register_rollup(p_level text, p_school uuid, p_year uuid, p_from date, p_to date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1efa743fb7249c361e19d3e854d14627
CREATE OR REPLACE FUNCTION v2.fn_register_rollup(p_level text DEFAULT 'school'::text, p_school uuid DEFAULT NULL::uuid, p_year uuid DEFAULT NULL::uuid, p_from date DEFAULT NULL::date, p_to date DEFAULT NULL::date)
 RETURNS TABLE("المستوى" text, "الاسم" text, "الطلاب" integer, "أيام_دراسة_مقررة" integer, "أيام_مرصودة" integer, "غياب_بعذر" integer, "غياب_بلا_عذر" integer, "تأخر" integer, "استئذان" integer, "نسبة_الغياب" numeric, "متجاوزو_الحد" integer, "متوسط_المواظبة" numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
with r as (select * from v2.fn_register_attendance(p_school,p_year,p_from,p_to,null,null,null))
select p_level,
  case p_level when 'school' then المدرسة when 'stage' then المرحلة
       when 'grade' then المدرسة||' · الصف '||الصف
       else المدرسة||' · الصف '||الصف||' / '||الفصل end,
  count(*)::int, max(أيام_دراسة_مقررة), coalesce(sum(أيام_مرصودة),0)::int,
  coalesce(sum(غياب_بعذر),0)::int, coalesce(sum(غياب_بلا_عذر),0)::int,
  coalesce(sum(تأخر),0)::int, coalesce(sum(استئذان),0)::int,
  case when coalesce(max(أيام_دراسة_مقررة),0)=0 or count(*)=0 then 0
       else round(sum(غياب_بلا_عذر)::numeric*100/(max(أيام_دراسة_مقررة)*count(*)),2) end,
  count(*) filter (where حرمان)::int,
  round(avg(رصيد_المواظبة),1)
from r group by 2 order by 2;
$function$
;
