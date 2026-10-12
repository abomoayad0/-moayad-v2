-- public.v2_reading_open(p_school uuid, p_period smallint, p_date date, p_skip_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1acad9c99c015238201f3be926686697
CREATE OR REPLACE FUNCTION public.v2_reading_open(p_school uuid, p_period smallint, p_date date DEFAULT CURRENT_DATE, p_skip_why text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid := v2.current_person(); v_sec uuid; v_grade smallint; v_id uuid;
        v_min int; v_gf int; v_gt int; v_k text; v_done boolean; v_min_chars int;
begin
  perform v2.assert_my_school(p_school,'استقطاعَ دقائق القراءة والكتابة');
  v_k := v2.fn_day_kind(p_school,p_date);
  if v_k is null or v_k not in ('study','exam') then
    raise exception 'اليوم % ليس يومَ دراسة — نوعُه: %', p_date, coalesce(v_k,'غيرُ معروف'); end if;

  v_min := v2.rule_n(p_school,'reading_minutes_per_period');
  v_gf  := v2.rule_n(p_school,'reading_grade_from');
  v_gt  := v2.rule_n(p_school,'reading_grade_to');

  select ep.section_id, cs.grade into v_sec, v_grade
    from v2.effective_periods(p_school, me, p_date) ep
    join v2.class_sections cs on cs.id = ep.section_id
   where ep.period_no = p_period limit 1;
  if v_sec is null then
    raise exception 'الحصّةُ % ليست لك في هذا اليوم', v2.ar_num(p_period); end if;
  if v_grade not between v_gf and v_gt then
    raise exception 'الصفُّ % خارجَ نطاق النصّ — والاستقطاعُ من الصفّ % إلى %',
      v2.ar_num(v_grade), v2.ar_num(v_gf), v2.ar_num(v_gt); end if;

  v_done := btrim(coalesce(p_skip_why,'')) = '';
  if not v_done then
    v_min_chars := v2.rule_n(p_school,'reason_min_chars');
    if length(btrim(p_skip_why)) < v_min_chars then
      raise exception 'تعذُّرُ الاستقطاع لا يُسجَّل بلا سببٍ مكتوبٍ — وأقلُّه % حرفًا', v2.ar_num(v_min_chars);
    end if;
  end if;

  insert into v2.reading_sessions(school_id,year_id,term_no,on_date,weekday,period_no,
      section_id,person_id,minutes,done,skipped_why_ar,recorded_by,recorded_role,is_test)
  values (p_school,
      (select e.year_id from v2.enrolments e where e.school_id=p_school and e.status='active' limit 1),
      v2.fn_term_of(p_school,p_date), p_date, extract(dow from p_date)::smallint, p_period,
      v_sec, me, v_min, v_done, nullif(btrim(coalesce(p_skip_why,'')),''),
      me, coalesce(v2.role_ar(v2.my_role()),'معلم'),
      coalesce((select test_mode from v2.schools where id=p_school),false))
  on conflict (school_id,person_id,on_date,period_no) where voided_at is null
  do update set done=excluded.done, skipped_why_ar=excluded.skipped_why_ar,
      minutes=excluded.minutes, recorded_at=now()
  returning id into v_id;

  return jsonb_build_object('ok',true,'session',v_id,'minutes',v_min,'done',v_done,
    'section_ar',(select label_ar from v2.class_sections where id=v_sec),
    'summary_ar', case when v_done
      then 'فُتح استقطاعُ '||v2.ar_num(v_min)||' دقائقَ في الحصّة '||v2.ar_num(p_period)
      else 'سُجّل تعذُّرُ الاستقطاع في الحصّة '||v2.ar_num(p_period)||' بسببٍ مكتوب' end,
    'note_ar', case when v_done
      then 'وارصد فيها مستوى من لم يُقَس بعد — فالاستقطاعُ لأجل المتابعة لا غرضًا بنفسه (س-٨-ا-٣/٠٤)'
      else 'والسببُ باقٍ في السجلّ لا يُحذف' end);
end $function$
;
