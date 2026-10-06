-- v2.fn_practice_balance(p_student uuid, p_year uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 045f696e52c9f9ed23eaa51a1a0bb2be
CREATE OR REPLACE FUNCTION v2.fn_practice_balance(p_student uuid, p_year uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS TABLE("موجب" numeric, "سالب" integer, "صافي_النقاط" numeric, "ممارسات" integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
select coalesce(sum(pp.points),0),
 (select count(*)::int from v2.practice_records r join v2.class_practices c on c.code=r.code
   where r.student_id=p_student and r.year_id=p_year and r.undone_at is null and c.polarity='negative'
     and (p_term is null or r.term_no=p_term)),
 coalesce(sum(pp.points),0),
 (select count(*)::int from v2.practice_records r where r.student_id=p_student and r.year_id=p_year
   and r.undone_at is null and (p_term is null or r.term_no=p_term))
from v2.practice_points pp
where pp.student_id=p_student and pp.year_id=p_year and (p_term is null or pp.term_no=p_term);
$function$
;
