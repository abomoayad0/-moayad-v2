-- v2.audit_badge_ready_not_given()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cabe93e77407750b939239867a5b8e4c
CREATE OR REPLACE FUNCTION v2.audit_badge_ready_not_given()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with sch as (
    select s.id, s.name_ar from v2.schools s
     where exists (select 1 from v2.enrolments e where e.school_id = s.id and e.status='active')),
  bg as (
    select distinct on (sc.id, b.code)
           sc.id as school_id, sc.name_ar as school_ar, b.code, b.title_ar, b.rule_kind
      from sch sc
      join v2.loyalty_badges b on (b.school_id = sc.id or b.school_id is null)
     where b.active and b.rule_kind <> 'manual'
     order by sc.id, b.code, (b.school_id is null))
  select 'شارةٌ استحقّها طلّابٌ ولم تُمنح · ' || bg.title_ar || ' · ' || bg.school_ar,
         'استحقَّها ' || v2.ar_count(c.n,'طالبٌ واحد','طالبان','طلّاب','طالبًا') ||
         ' ولم تُمنح لهم — فالمحرّكُ لم يُشغَّل · تُمنح بنداء v2_badge_run',
         'انتبه'
    from bg
    cross join lateral (
      select count(*) as n from v2.enrolments e
       where e.school_id = bg.school_id and e.status = 'active'
         and v2.badge_earned(bg.school_id, e.student_id, bg.code)
         and not exists (
           select 1 from v2.badge_awards w
            where w.student_id = e.student_id and w.badge_code = bg.code
              and w.year_id is not distinct from
                  (select y.id from v2.academic_years y
                    where y.school_id = bg.school_id and y.is_current limit 1))) c
   where c.n > 0;
$function$
;
