-- v2.fn_record_attendance(p_student uuid, p_date date, p_state text, p_term smallint, p_minutes_late smallint, p_note text, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5a9ec843e9d54ec9e5ad1e11e5d02b2a
CREATE OR REPLACE FUNCTION v2.fn_record_attendance(p_student uuid, p_date date, p_state text, p_term smallint DEFAULT 1, p_minutes_late smallint DEFAULT NULL::smallint, p_note text DEFAULT NULL::text, p_by uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare
  v_school uuid; v_year uuid; v_id uuid; v_open numeric; v_kind text;
  v_ex boolean; v_days int; v_lad record; it record; v_case uuid; v_consec boolean;
begin
  select e.school_id, e.year_id into v_school, v_year
  from v2.enrolments e where e.student_id=p_student and e.status='active'
  order by e.created_at desc limit 1;
  if v_school is null then raise exception 'الطالب لا قيد فعّال له في سنة دراسية'; end if;

  v_kind := v2.fn_day_kind(v_school, p_date);
  if v_kind is null then
    raise exception 'اليوم % خارج التقويم الدراسي المنزَّل لهذه المدرسة — لا يُرصد', p_date;
  end if;
  if v_kind not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة: %. ولا يُرصد فيه حضور ولا غياب', p_date,
      case v_kind when 'holiday' then 'إجازة' when 'weekend' then 'عطلة نهاية الأسبوع'
                  when 'suspended' then 'دراسة معلّقة' else v_kind end;
  end if;

  insert into v2.attendance(school_id,year_id,term_no,student_id,on_date,state,minutes_late,recorded_by,note)
  values (v_school,v_year,p_term,p_student,p_date,p_state,p_minutes_late,p_by,p_note)
  on conflict (student_id,on_date) do update
    set state=excluded.state, minutes_late=excluded.minutes_late,
        recorded_by=excluded.recorded_by, note=excluded.note
  returning id into v_id;

  if not exists (select 1 from v2.attendance_ledger where student_id=p_student and year_id=v_year and kind='opening') then
    select value_num into v_open from v2.conduct_rules where key='attendance.total';
    insert into v2.attendance_ledger(school_id,year_id,student_id,kind,points,reason)
    values (v_school,v_year,p_student,'opening',v_open,
      'تخصيص (100) درجة للمواظبة خلال العام الدراسي — م31 بند 2 · CONDUCT-1447-OFF ص47');
  end if;

  if p_state <> 'absent' then return v_id; end if;
  v_ex := v2.fn_is_excused(p_student, p_date);

  if not v_ex and not exists (
      select 1 from v2.attendance_ledger l
       where l.student_id=p_student and l.year_id=v_year and l.kind='deduction' and l.on_date=p_date) then
    insert into v2.attendance_ledger(school_id,year_id,student_id,kind,points,on_date,reason,by_person)
    values (v_school,v_year,p_student,'deduction',-1,p_date,
      'حسم درجة عن يوم غياب بدون عذر ('||p_date||') — م31 · CONDUCT-1447-OFF ص47', p_by);
  end if;

  v_days := v2.fn_absence_days(p_student, v_year, v_ex);
  select * into v_lad from v2.absence_ladder where excused = v_ex and days <= v_days order by days desc limit 1;
  if v_lad.id is null then return v_id; end if;
  if exists (select 1 from v2.absence_cases c
             where c.student_id=p_student and c.year_id=v_year and c.excused=v_ex and c.ladder_id=v_lad.id) then
    return v_id;
  end if;

  v_consec := (
    select count(a.id) = 3 from (
      select d.on_g from v2.calendar_days d
       join v2.calendar_years y on y.id=d.year_id
       join v2.schools s on s.calendar_scope=y.scope_key
      where s.id=v_school and d.day_kind in ('study','exam') and d.on_g <= p_date
      order by d.on_g desc limit 3) q
    left join v2.attendance a on a.student_id=p_student and a.on_date=q.on_g and a.state='absent');

  insert into v2.absence_cases(school_id,year_id,term_no,student_id,excused,days_count,ladder_id,consecutive,triggered_on)
  values (v_school,v_year,p_term,p_student,v_ex,v_days,v_lad.id,v_consec,p_date)
  returning id into v_case;

  for it in select * from v2.absence_ladder_items where ladder_id=v_lad.id order by ord loop
    if it.kind='external_report' and it.text_ar like '%متصلة%' and not v_consec then
      insert into v2.absence_tasks(case_id,item_id,ord,kind,text_ar,owner_role,origin,status,skip_reason)
      values (v_case,it.id,it.ord,it.kind,it.text_ar,it.owner_role,it.origin,'skipped',
        'لا ينطبق: لم يغب ثلاثة أيام دراسة متتالية — والعطل والإجازات لا تقطع الاتصال ولا تُعدّ منه');
    else
      insert into v2.absence_tasks(case_id,item_id,ord,kind,text_ar,owner_role,origin,status)
      values (v_case,it.id,it.ord,it.kind,it.text_ar,it.owner_role,it.origin,'open');
    end if;
  end loop;
  return v_id;
end $function$
;
