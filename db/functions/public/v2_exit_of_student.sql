-- public.v2_exit_of_student(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bec1846fa0f64f8627f59ecbfb868fde
CREATE OR REPLACE FUNCTION public.v2_exit_of_student(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v_days int;
begin
  perform v2.assert_my_student(p_student,'سجلَّ خروج الطالب');
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  v_days := (v2.rule_n(sc,'exit_window_days'))::int;

  return jsonb_build_object(
    'window_days', v_days,
    'month_count', (select count(*) from v2.class_exits x
        where x.student_id=p_student and x.on_date >= current_date - v_days),
    'month_warn', v2.rule_n(sc,'card_exit_month_warn'),
    'out_now', exists (select 1 from v2.class_exits x
        where x.student_id=p_student and x.back_at is null),
    'today_count', (select count(*) from v2.class_exits x
        where x.student_id=p_student and x.on_date = current_date),
    'today_max', v2.rule_n(sc,'exit_max_per_day_student'),
    'rows', coalesce((select jsonb_agg(jsonb_build_object(
        'exit',x.id,'on_date',x.on_date,'period',x.period_no,
        'to_ar',x.to_where_ar,'note_ar',x.note_ar,
        'minutes', case when x.back_at is null then null
                   else greatest(0,(extract(epoch from (x.back_at - x.out_at))/60)::int) end,
        'returned', x.back_at is not null,
        'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p where p.id=x.out_by))
        order by x.out_at desc)
      from v2.class_exits x
      where x.student_id=p_student and x.on_date >= current_date - v_days),'[]'::jsonb));
end $function$
;
