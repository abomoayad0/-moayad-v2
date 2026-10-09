-- v2.fn_apply_absence(p_student uuid, p_date date, p_term smallint, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 eb08e9635d8bfa7396bdb04c07b8fc44
CREATE OR REPLACE FUNCTION v2.fn_apply_absence(p_student uuid, p_date date, p_term smallint, p_by uuid DEFAULT NULL::uuid)
 RETURNS void
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_year uuid; v_open numeric; v_ex boolean;
        v_days int; v_lad record; it record; v_case uuid; v_consec boolean;
        v_txt text;
begin
  select e.school_id, e.year_id into v_school, v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;

  if not exists (select 1 from v2.attendance_ledger where student_id=p_student and year_id=v_year and kind='opening') then
    select value_num, text_ar into v_open, v_txt from v2.conduct_rules where key='attendance.total';
    insert into v2.attendance_ledger(school_id,year_id,student_id,kind,points,reason)
    values (v_school,v_year,p_student,'opening',v_open,
      v_txt||' — '||v2.cite('attendance.total'));
  end if;

  v_ex := v2.fn_is_excused(p_student,p_date);
  perform v2.fn_notify_absence_day(p_student, p_date, p_by);
  if not v_ex and not exists (select 1 from v2.attendance_ledger l
      where l.student_id=p_student and l.year_id=v_year and l.kind='deduction' and l.on_date=p_date) then
    insert into v2.attendance_ledger(school_id,year_id,student_id,kind,points,on_date,reason,by_person)
    values (v_school,v_year,p_student,'deduction',-1,p_date,
      'حسم درجة عن يوم غياب بدون عذر ('||p_date||') — '||v2.cite('attendance.deduct_per_day'), p_by);
  end if;

  v_days := v2.fn_absence_days(p_student,v_year,v_ex);
  select * into v_lad from v2.absence_ladder where excused=v_ex and days<=v_days order by days desc limit 1;
  if v_lad.id is null then return; end if;
  if exists (select 1 from v2.absence_cases c
             where c.student_id=p_student and c.year_id=v_year and c.excused=v_ex and c.ladder_id=v_lad.id) then
    return; end if;

  v_consec := (select count(a.id)=3 from (
      select d.on_g from v2.calendar_days d
       join v2.calendar_years y on y.id=d.year_id
       join v2.schools s on s.calendar_scope=y.scope_key
      where s.id=v_school and d.day_kind in ('study','exam') and d.on_g<=p_date
      order by d.on_g desc limit 3) q
    left join v2.attendance a on a.student_id=p_student and a.on_date=q.on_g and a.state='absent');

  insert into v2.absence_cases(school_id,year_id,term_no,student_id,excused,days_count,ladder_id,consecutive,triggered_on)
  values (v_school,v_year,p_term,p_student,v_ex,v_days,v_lad.id,v_consec,p_date) returning id into v_case;

  for it in select * from v2.absence_ladder_items where ladder_id=v_lad.id order by ord loop
    if it.kind='external_report' and it.text_ar like '%متصلة%' and not v_consec then
      insert into v2.absence_tasks(case_id,item_id,ord,kind,text_ar,owner_role,origin,status,skip_reason)
      values (v_case,it.id,it.ord,it.kind,it.text_ar,it.owner_role,it.origin,'skipped',
        'لا ينطبق: لم يغب ثلاثة أيام دراسة متتالية');
    else
      insert into v2.absence_tasks(case_id,item_id,ord,kind,text_ar,owner_role,origin,status)
      values (v_case,it.id,it.ord,it.kind,it.text_ar,it.owner_role,it.origin,'open');
    end if;
  end loop;
end $function$
;
