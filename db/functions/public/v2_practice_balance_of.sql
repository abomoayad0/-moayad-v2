-- public.v2_practice_balance_of(p_student uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3429b71433af819920978675c6d2cbe8
CREATE OR REPLACE FUNCTION public.v2_practice_balance_of(p_student uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; tm smallint; v_bal numeric; v_pos numeric; v_neg numeric;
        n_pos int; n_neg int;
begin
  perform v2.assert_my_student(p_student,'رصيدَ ممارسات الطالب');
  select e.school_id, e.year_id into sc, yr from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  tm := coalesce(p_term, v2.fn_term_of(sc, current_date));

  select coalesce(sum(pp.points),0),
         coalesce(sum(case when pp.points > 0 then pp.points else 0 end),0),
         coalesce(sum(case when pp.points < 0 then -pp.points else 0 end),0)
    into v_bal, v_pos, v_neg
    from v2.practice_points pp
   where pp.student_id=p_student and pp.year_id=yr and pp.term_no=tm;

  select count(*) filter (where c.polarity='positive'),
         count(*) filter (where c.polarity='negative')
    into n_pos, n_neg
    from v2.practice_records r join v2.class_practices c on c.code=r.code
   where r.student_id=p_student and r.year_id=yr and r.term_no=tm and r.undone_at is null;

  return jsonb_build_object(
    'term_no', tm,
    'balance', v_bal,
    'balance_ar', case when v_bal = 0 then 'رصيدُه صفر'
        when v_bal > 0 then 'رصيدُه '||v2.ar_num(v_bal)
        else 'رصيدُه '||v2.ar_num(v_bal)||' — وهو تحت الصفر' end,
    'earned', v_pos, 'deducted', v_neg,
    'count_positive', n_pos, 'count_negative', n_neg,
    'counts_ar', case when n_pos = 0 and n_neg = 0 then 'لم يُرصد له شيءٌ هذا الفصل'
      else concat_ws(' · ',
        v2.ar_count0(n_pos,'لم تُرصد له إيجابيّة',
            'رُصدت له إيجابيّةٌ واحدة','رُصدت له إيجابيّتان',
            'رُصدت له إيجابيّات','رُصدت له إيجابيّة'),
        v2.ar_count0(n_neg,'ولا سالبة',
            'وسالبةٌ واحدة','وسالبتان','وسالبات','وسالبة')) end,
    'negative_weighed', v2.rule_n(sc,'practice_negative_weighed') = 1,
    'spend_ar','ورصيدُ الممارسات مستقلٌّ تمامًا عن دليل السلوك ولا يمسُّه · ومصرفُه في درجة المادّة لم يُبنَ بعد، فهو مرآةٌ لا درجة',
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object(
          'record', r.id, 'code', r.code,
          'title_ar', c.title_ar, 'polarity', c.polarity,
          'on_ar', v2.fn_to_hijri(r.on_date),
          'period_no', r.period_no, 'period_ar', v2.period_ar(r.period_no),
          'subject_ar', r.subject_ar,
          'points', r.points,
          'counted', (select pp.points from v2.practice_points pp where pp.record_id = r.id),
          'counted_ar', case
              when (select pp.points from v2.practice_points pp where pp.record_id = r.id) is null
                then 'لم تُحسب في الرصيد'
              else v2.ar_num((select pp.points from v2.practice_points pp where pp.record_id = r.id)) end,
          'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p where p.id = r.by_person),
          'escalated', r.escalated_record is not null)
        order by r.on_date desc, r.created_at desc)
      from v2.practice_records r
      join v2.class_practices c on c.code = r.code
      where r.student_id=p_student and r.year_id=yr and r.term_no=tm and r.undone_at is null),
      '[]'::jsonb));
end $function$
;
