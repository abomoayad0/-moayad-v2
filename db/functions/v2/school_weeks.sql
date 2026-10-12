-- v2.school_weeks(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b10eb8daf8865a266a2dfa599f19842c
CREATE OR REPLACE FUNCTION v2.school_weeks(p_school uuid)
 RETURNS TABLE(week_id uuid, term_no smallint, week_no smallint, from_h text, to_h text, from_g date, to_g date, h_months text, is_exam boolean, note_ar text, is_custom boolean, custom_why text, custom_at timestamp with time zone, base_from_h text, base_to_h text, base_is_exam boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select w.id, w.term_no, w.week_no,
         coalesce(o.from_h, w.from_h), coalesce(o.to_h, w.to_h),
         coalesce(o.from_g, w.from_g), coalesce(o.to_g, w.to_g),
         w.h_months,
         coalesce(o.is_exam_week, w.is_exam_week, false),
         coalesce(o.note_ar, w.note),
         (o.id is not null), o.reason_ar, o.set_at,
         w.from_h, w.to_h, coalesce(w.is_exam_week,false)
    from v2.schools s
    join v2.calendar_years y on y.scope_key = s.calendar_scope
    join v2.calendar_weeks w on w.year_id = y.id
    left join v2.calendar_week_overrides o
           on o.week_id = w.id and o.school_id = s.id and o.voided_at is null
   where s.id = p_school
$function$
;
