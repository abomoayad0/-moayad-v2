-- public.v2_exit_of_student(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7cf0afe1ab99ae7696e91adb1c6295c9
CREATE OR REPLACE FUNCTION public.v2_exit_of_student(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v_days int; n_today int; n_month int; v_max int; v_warn int;
begin
  perform v2.assert_my_student(p_student,'سجلَّ خروج الطالب');
  select e.school_id into sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  v_days := (v2.rule_n(sc,'exit_window_days'))::int;
  v_max  := (v2.rule_n(sc,'exit_max_per_day_student'))::int;
  v_warn := (v2.rule_n(sc,'card_exit_month_warn'))::int;
  select count(*) into n_today from v2.class_exits x
   where x.student_id=p_student and x.on_date = current_date;
  select count(*) into n_month from v2.class_exits x
   where x.student_id=p_student and x.on_date >= current_date - v_days;

  return jsonb_build_object(
    'window_days', v_days,
    'today_count', n_today, 'today_max', v_max,
    'today_ar', case when n_today = 0 then 'لم يخرج اليومَ'
      else 'خرج اليومَ '||v2.ar_count(n_today,'مرّةً واحدة','مرّتين','مرّات','مرّة')
           ||' من '||v2.ar_num(v_max) end,
    'month_count', n_month, 'month_warn', v_warn,
    'month_ar', case when n_month = 0
      then 'ولا خروجَ له في '||v2.ar_num(v_days)||' يومًا'
      else 'وفي '||v2.ar_num(v_days)||' يومًا '||
           v2.ar_count(n_month,'مرّةً واحدة','مرّتين','مرّات','مرّة') end,
    'over_warn', n_month > v_warn,
    'warn_ar', case when n_month > v_warn
      then 'وهو فوق حدِّ لوحة التحكّم ('||v2.ar_num(v_warn)||') — فانظر في سببه' end,
    'out_now', exists (select 1 from v2.class_exits x
        where x.student_id=p_student and x.back_at is null),
    'rows', coalesce((select jsonb_agg(jsonb_build_object(
        'exit',x.id,'on_date',x.on_date,'on_ar',v2.fn_to_hijri(x.on_date),
        'period',x.period_no,'period_ar',v2.period_ar(x.period_no),
        'to_ar',x.to_where_ar,'note_ar',x.note_ar,
        'minutes', case when x.back_at is null then null
                   else greatest(0,(extract(epoch from (x.back_at - x.out_at))/60)::int) end,
        'minutes_ar', case when x.back_at is null then 'لم يعد بعد'
                   else 'غاب '||v2.ar_count(
                        greatest(0,(extract(epoch from (x.back_at - x.out_at))/60)::int),
                        'دقيقةً واحدة','دقيقتين','دقائق','دقيقة') end,
        'returned', x.back_at is not null,
        'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p where p.id=x.out_by))
        order by x.out_at desc)
      from v2.class_exits x
      where x.student_id=p_student and x.on_date >= current_date - v_days),'[]'::jsonb));
end $function$
;
