-- v2.attendance_result(p_student uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e897ac340b23b71b6e5da9b668a2e45b
CREATE OR REPLACE FUNCTION v2.attendance_result(p_student uuid, p_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare a record; v_year uuid; v_bal numeric; v_ded numeric; v_ex boolean;
        v_grade smallint; v_gv jsonb;
        v_case record; v_tasks jsonb; v_reg record;
        v_year_days int; v_abs int; v_pct numeric; v_limit int; v_total numeric; v_dpct numeric;
        v_denied boolean;
begin
  select * into a from v2.attendance where student_id=p_student and on_date=p_date;
  if a.id is null then return jsonb_build_object('ok', false, 'why_ar','لا سجلَّ لهذا اليوم'); end if;
  v_year := a.year_id;
  v_bal := v2.fn_attendance_balance(p_student, v_year);
  select coalesce(-sum(points),0) into v_ded from v2.attendance_ledger
   where student_id=p_student and year_id=v_year and kind='deduction';
  v_ex := case when a.state='absent' then v2.fn_is_excused(p_student, p_date) else null end;
  select e.grade into v_grade from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;

  select c.*, l.days, l.excused, l.article_no, l.source_page
    into v_case
    from v2.absence_cases c join v2.absence_ladder l on l.id = c.ladder_id
   where c.student_id=p_student and c.year_id=v_year and c.triggered_on = p_date
   order by c.created_at desc limit 1;

  if v_case.id is not null then
    select coalesce(jsonb_agg(jsonb_build_object(
        'task',t.id,'kind',t.kind,'text',t.text_ar,'owner',t.owner_role,
        'status',t.status,'standing',t.is_standing,
        'ev_text',t.ev_text,'skip_reason',t.skip_reason) order by t.ord),'[]'::jsonb)
      into v_tasks from v2.absence_tasks t where t.case_id = v_case.id;
  end if;

  -- 🔑 أرقامُ الحرمان من سجلّ المواظبة نفسِه — مصدرٌ واحدٌ لا حسابان
  select "أيام_دراسة_مقررة", "نسبة_الغياب", "غياب_بلا_عذر", "حرمان"
    into v_year_days, v_pct, v_abs, v_denied
    from v2.fn_register_attendance(a.school_id, v_year, null, null, null, null, p_student) limit 1;

  select value_num into v_dpct from v2.conduct_rules where key='attendance.denial_pct';
  select value_num into v_total from v2.conduct_rules where key='attendance.total';
  v_limit := case when coalesce(v_year_days,0)=0 then null
                  else floor(v_year_days * v_dpct / 100.0)::int + 1 end;

  return jsonb_build_object(
    'ok', true,
    'student', (select full_name from v2.students where id=p_student),
    'on_date', p_date,
    'on_date_ar', v2.fn_to_hijri(p_date)||' هـ',
    'state', a.state,
    'state_ar', case a.state when 'present' then 'حاضر' when 'absent' then 'غائب'
                             when 'late' then 'متأخّر' else 'بإذن' end,
    'minutes_late', a.minutes_late,
    'excused', v_ex,
    'excused_ar', case when a.state <> 'absent' then null
                       when v_ex then 'غيابٌ بعذرٍ مقبولٍ مسجَّل — ولا حسمَ عليه'
                       else 'غيابٌ بغير عذرٍ — وحُسمت عنه درجةٌ واحدة' end,
    'balance', case when (v2.grade_view('attendance', v_bal, v_grade, v_total)->>'qualitative')::boolean
                       then null else v_bal end,
    'balance_ar', (v2.grade_view('attendance', v_bal, v_grade, v_total)->>'show_ar'),
    'grade_view', v2.grade_view('attendance', v_bal, v_grade, v_total),
    'deducted_total', v_ded,
    'absent_unexcused_days', v_abs,
    'year_study_days', v_year_days,
    'absence_pct_of_year', v_pct,
    'denial_limit_days', v_limit,
    'denied', coalesce(v_denied,false),
    'denial_ar', v2.denial_line_ar(coalesce(v_abs,0), v_limit, v_year_days),
    'denial_watch_ar', case
      when v_limit is null then null
      when coalesce(v_denied,false) or coalesce(v_abs,0) >= v_limit then
        'تجاوز حدَّ الحرمان — '||v2.ar_num(coalesce(v_abs,0))||' من '||v2.ar_num(v_limit)||' · '||
        'ولا يصدر قرارُ الحرمان إلّا من المدير بعد إنذارِ وليّ الأمر وعرضِ الحالة على لجنة التوجيه'
      when coalesce(v_abs,0) >= ceil(v_limit * 0.7) then
        'يقترب من حدّ الحرمان — '||v2.ar_num(coalesce(v_abs,0))||' من '||v2.ar_num(v_limit)
      else null end,
    'case', case when v_case.id is null then null else jsonb_build_object(
        'id', v_case.id,
        'ladder_ar', 'عتبةُ '||v2.ar_num(v_case.days)||' أيّامٍ · غيابٌ '||
                     case when v_case.excused then 'بعذر' else 'بغير عذر' end||
                     ' · م'||v_case.article_no||' '||v_case.source_page,
        'consecutive', v_case.consecutive,
        'consecutive_ar', case when v_case.consecutive
                               then 'ثلاثةُ أيّامٍ دراسيّةٍ متّصلة — فبندُ مخاطبة الجهات ينطبق'
                               else 'غيابٌ منفصلٌ — فبندُ المتّصل لا ينطبق' end,
        'tasks', coalesce(v_tasks,'[]'::jsonb)) end,
    'source_ar','أرقامُ الغياب والحرمان من سجلّ المواظبة نفسِه — فلا يختلف رقمٌ بين بطاقةٍ وتقرير');
end $function$
;
