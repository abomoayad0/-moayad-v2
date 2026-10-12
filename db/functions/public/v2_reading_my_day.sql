-- public.v2_reading_my_day(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 71d4a50f8de6a5890329e339c2b2be12
CREATE OR REPLACE FUNCTION public.v2_reading_my_day(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid := v2.current_person(); d record; rows jsonb;
begin
  perform v2.assert_my_school(p_school,'قراءةَ استقطاع القراءة والكتابة');
  select * into d from v2.reading_due(p_school, me, p_date);

  select coalesce(jsonb_agg(jsonb_build_object(
      'period', x.period_no,
      'section_ar', coalesce(x.label_ar,'—'),
      'grade', x.grade,
      'subject_ar', coalesce(x.subject_ar,'—'),
      'state_ar', case when x.done is true then '🟢 نُفِّذ'
                       when x.done is false then '🟠 لم يُنفَّذ — '||coalesce(x.why,'بلا سبب')
                       else '🔴 لم يُرصد بعد' end,
      'session', x.sid,
      'marks_n', coalesce(x.marks_n,0)
    ) order by x.period_no), '[]'::jsonb) into rows
    from (select ep.period_no, cs.label_ar, cs.grade, ep.subject_ar,
                 rs.id sid, rs.done, rs.skipped_why_ar why,
                 (select count(*) from v2.skill_marks sm
                   where sm.session_id = rs.id and sm.voided_at is null) marks_n
            from v2.effective_periods(p_school, me, p_date) ep
            join v2.class_sections cs on cs.id = ep.section_id
            left join v2.reading_sessions rs
              on rs.school_id=p_school and rs.person_id=me and rs.on_date=p_date
             and rs.period_no=ep.period_no and rs.voided_at is null
           where cs.grade between d.g_from and d.g_to) x;

  return jsonb_build_object('ok',true,'on_date',p_date,
    'eligible',d.eligible_n,'required',d.required_n,'done',d.done_n,
    'skipped',d.skipped_n,'missing',d.missing_n,
    'minutes',d.minutes,'rows',rows,
    'summary_ar', case when d.eligible_n = 0
      then 'لا حصّةَ لك اليومَ في الصفوف '||v2.ar_num(d.g_from)||'–'||v2.ar_num(d.g_to)||' فلا استقطاعَ عليك'
      else 'عليك '||v2.ar_count(d.required_n,'حصّةٌ واحدة','حصّتان','حصصٍ','حصّةً')
           ||' × '||v2.ar_num(d.minutes)||' دقائق · نُفِّذ '||v2.ar_num(d.done_n)
           ||case when d.missing_n>0 then ' · وبقي '||v2.ar_num(d.missing_n) else '' end end,
    'basis_ar','سياسةُ الدليل — س-٨-ا-٣ سياسة ٠٤ ص٢٠٩ · والرصدُ موضعُه سجلُّ متابعة المهارات (سياسة ٠١ وخطوة ٠٣)');
end $function$
;
