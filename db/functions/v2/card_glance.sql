-- v2.card_glance(p_school uuid, p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 483bbc151f295841ccc5bce274447b0c
CREATE OR REPLACE FUNCTION v2.card_glance(p_school uuid, p_student uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
AS $function$
declare v_days int; n_abs int; n_late int; n_per int; n_exit int; v_last date; v_silent int;
begin
  v_days := (v2.rule_n(p_school,'card_glance_days'))::int;
  select count(*) into n_abs  from v2.attendance a
   where a.student_id=p_student and a.state='absent' and a.on_date >= p_date - v_days;
  select count(*) into n_late from v2.attendance a
   where a.student_id=p_student and a.state='late' and a.on_date >= p_date - v_days;
  select count(*) into n_per  from v2.period_attendance pa
   where pa.student_id=p_student and pa.state='absent' and pa.on_date >= p_date - v_days;
  select count(*) into n_exit from v2.class_exits x
   where x.student_id=p_student and x.on_date >= p_date - v_days;
  select max(ce.on_date) into v_last from v2.card_events ce
   where ce.student_id=p_student and ce.polarity='positive' and ce.undone_at is null;
  v_silent := case when v_last is null then null else (p_date - v_last)::int end;

  return jsonb_build_object(
    'window_days', v_days,
    'window_ar', 'في '||v2.ar_count(v_days,'يومٍ واحد','يومين','أيّام','يومًا')||' مضت',
    'absent_days', n_abs,
    'absent_ar', case when n_abs = 0 then 'لم يغب يومًا'
        else 'غاب '||v2.ar_count(n_abs,'يومًا واحدًا','يومين','أيّام','يومًا') end,
    'late_days', n_late,
    'late_ar', case when n_late = 0 then 'ولا تأخّر'
        else 'وتأخّر '||v2.ar_count(n_late,'يومًا واحدًا','يومين','أيّام','يومًا') end,
    'absent_periods', n_per,
    'absent_periods_ar', case when n_per = 0 then 'ولا غابَ عن حصّة'
        else 'وغاب عن '||v2.ar_count(n_per,'حصّةٍ واحدة','حصّتين','حصص','حصّة') end,
    'exits_month', n_exit,
    'exits_ar', case when n_exit = 0 then 'ولا خرج من الفصل'
        else 'وخرج من الفصل '||v2.ar_count(n_exit,'مرّةً واحدة','مرّتين','مرّات','مرّة') end,
    'silent_days', v_silent,
    'silent_ever', v_last is not null,
    'silent_ar', case when v_last is null then 'لم تُرصد له إيجابيّةٌ قطُّ منذ قيده'
                      when v_silent >= v2.rule_n(p_school,'card_silent_days')
                        then 'مضى '||v2.ar_count(v_silent,'يومٌ واحد','يومان','أيّام','يومًا')||
                             ' بلا إيجابيّةٍ واحدة — فانظر إليه'
                      else null end,
    'silent_limit', v2.rule_n(p_school,'card_silent_days'));
end $function$
;
