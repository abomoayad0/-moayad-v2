-- v2.fn_denial_warn(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a6e7c1360376c82c6a2264fb8ff84475
CREATE OR REPLACE FUNCTION v2.fn_denial_warn(p_student uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_year uuid; v_abs int; v_limit int; v_before numeric;
        v_id uuid; v_ev uuid; v_name text; v_test boolean; v_year_days int;
        msg text; st text; dt text; hn text; cx text;
begin
  select e.school_id, e.year_id into v_school, v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;
  if v_school is null then return null; end if;

  select id into v_id from v2.denial_actions
   where student_id=p_student and year_id=v_year and kind='warning';
  if v_id is not null then return v_id; end if;

  select "أيام_دراسة_مقررة", "غياب_بلا_عذر" into v_year_days, v_abs
    from v2.fn_register_attendance(v_school, v_year, null, null, null, null, p_student) limit 1;
  v_limit := v2.denial_limit(v_year_days);
  if v_limit is null then return null; end if;

  select value_num into v_before from v2.conduct_rules where key='denial.warn_before_days';
  if coalesce(v_abs,0) < v_limit - coalesce(v_before,3) then return null; end if;

  select s.full_name into v_name from v2.students s where s.id=p_student;
  v_test := coalesce((select test_mode from v2.schools where id=v_school),false);

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
  values (v_school,'absence_report',current_date,p_student,
      'تنبيهٌ مهمّ: يقترب ابنكم من حدّ الحرمان',
      'بلغ غيابُ ابنكم '||coalesce(v2.fn_display_name(v_name),'')||' بغير عذرٍ '||
      v2.ar_count(coalesce(v_abs,0),'يومًا واحدًا','يومين','أيّام','يومًا')||
      ' · وحدُّ الحرمان من الانتقال '||v2.ar_num(v_limit)||' يومًا من أصل '||
      v2.ar_num(v_year_days)||' يومًا دراسيًّا. '||
      'فنرجو متابعةَ حضوره وتقديمَ ما لديكم من أعذارٍ في مدّتها.',
      'denial_actions',null,'all',true,'تواصل مع المدرسة', v_test)
  returning id into v_ev;

  insert into v2.denial_actions(school_id,student_id,year_id,kind,days_absent,limit_days,
      by_person,event_id,is_test)
  values (v_school,p_student,v_year,'warning',v_abs,v_limit,v2.current_person(),v_ev,v_test)
  returning id into v_id;

  update v2.events set ref_id = v_id where id = v_ev;
  return v_id;
exception when others then
  get stacked diagnostics st=returned_sqlstate, msg=message_text, dt=pg_exception_detail,
    hn=pg_exception_hint, cx=pg_exception_context;
  perform v2.fn_log_error(msg,'fn_denial_warn','المواظبة','إنذارُ قرب حدّ الحرمان',
    jsonb_build_object('student',p_student),st,dt,hn,cx,'engine','error');
  return null;
end $function$
;
