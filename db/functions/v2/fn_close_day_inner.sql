-- v2.fn_close_day_inner(p_school uuid, p_date date, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 346d796be067481baf6ce4d33957526f
CREATE OR REPLACE FUNCTION v2.fn_close_day_inner(p_school uuid, p_date date, p_by uuid DEFAULT NULL::uuid)
 RETURNS TABLE("المقيدون" integer, "المرصودون" integer, "غياب" integer, "تأخر" integer, "مشتق" integer, "لم_يُرصد" integer, "أحداث" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st record; r record; v_year uuid; k text;
  n_abs int:=0; n_late int:=0; n_der int:=0; n_none int:=0; n_ev int:=0; n_enr int:=0; ins int;
  v_ev uuid; v_prob int; v_scope text; v_stage text; g record;
begin
  k := v2.fn_day_kind(p_school,p_date);
  if k is null or k not in ('study','exam') then
    raise exception 'اليوم % ليس يوم دراسة — لا يُقفل', p_date; end if;
  if exists (select 1 from v2.day_closures c where c.school_id=p_school and c.on_date=p_date and c.reopened_at is null) then
    raise exception 'يوم % مقفَل سلفاً — لا يُقفل مرتين إلا بإعادة فتح موثّقة', p_date; end if;

  select id into v_year from v2.academic_years where school_id=p_school and is_current limit 1;
  select count(*) into n_enr from v2.enrolments e where e.school_id=p_school and e.status='active';

  for r in select e.student_id sid from v2.enrolments e
            where e.school_id=p_school and e.status='active'
              and not exists (select 1 from v2.attendance a where a.student_id=e.student_id and a.on_date=p_date) loop
    insert into v2.attendance(school_id,year_id,term_no,student_id,on_date,state,assembly_state,source,note)
    select p_school,v_year,1,r.sid,p_date,
      case when pa.state='absent' then 'absent' else 'present' end,
      case when pa.state='absent' then 'not_arrived' else 'attended' end,
      'derived_from_periods','مشتقّ من سجل الحصة الأولى — لم يرصده المساعد الإداري'
    from v2.period_attendance pa where pa.student_id=r.sid and pa.on_date=p_date and pa.period_no=1;
    get diagnostics ins = row_count;
    if ins > 0 then n_der := n_der + 1; else n_none := n_none + 1; end if;
  end loop;

  if n_none > 0 then
    insert into v2.events(school_id,kind,on_date,title_ar,body_ar,needs_action,action_ar)
    values (p_school,'other',p_date,'طلاب لم يُرصدوا اليوم',
      n_none||' طالباً لم يرصدهم المساعد الإداري ولا ظهروا في سجل الحصة الأولى، فلا تُعرف حالتهم. ولم يُحسب لهم حضور ولا غياب.',
      true,'رصدهم ثم إعادة فتح اليوم وإقفاله');
    n_ev := n_ev + 1;
  end if;

  update v2.attendance set day_status='closed' where school_id=p_school and on_date=p_date;

  select e2.stage into v_stage from v2.enrolments e2 where e2.school_id=p_school limit 1;
  v_scope := case when v_stage='primary' then 'primary' else 'intermediate_secondary' end;

  for st in select a.* from v2.attendance a where a.school_id=p_school and a.on_date=p_date loop
    if st.state='absent' then
      n_abs := n_abs + 1;
      perform v2.fn_apply_absence(st.student_id, p_date, st.term_no, p_by);
      update v2.behavior_records br set note = coalesce(br.note,'')||
          ' · ومعها تأخّرٌ '||v2.ar_num(coalesce(st.minutes_from_assembly,0))||' دقيقة (رصدٌ آليٌّ عند الإقفال)'
        where br.student_id=st.student_id and br.problem_id=v_prob
          and br.status<>'voided' and br.created_at::date=current_date
          and coalesce(br.note,'') not like '%رصدٌ آليٌّ عند الإقفال%';
      insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,ref_table,ref_id,needs_action,action_ar)
      values (p_school,'absence_report',p_date,st.student_id,'بلاغ غياب',
        'غاب ابنكم اليوم عن الدراسة. ولكم ثلاثة أيام عمل لتقديم العذر مع ما يثبته — م31 بند 6.',
        'attendance',st.id,true,'إرفاق العذر') returning id into v_ev;
      n_ev := n_ev + 1;
      for g in select id from v2.guardians where student_id=st.student_id loop
        insert into v2.event_deliveries(event_id,channel,to_guardian) values (v_ev,'guardian_portal',g.id),(v_ev,'whatsapp',g.id);
      end loop;
    elsif st.state='late' then
      n_late := n_late + 1;
      select id into v_prob from v2.conduct_problems where stage_scope=v_scope and mode='onsite'
        and target='general' and text_ar like 'التأخر الصباحي%' limit 1;
      if v_prob is not null
         and not exists (select 1 from v2.behavior_records br
                          where br.student_id=st.student_id and br.problem_id=v_prob
                            and br.status<>'voided' and br.created_at::date=current_date) then
        perform v2.fn_record_behavior(st.student_id,v_prob,st.term_no,null,'الاصطفاف',
          'تأخر صباحي '||coalesce(st.minutes_from_assembly,0)||' دقيقة — رصد آلي عند إقفال اليوم',null,false,false,false,false,p_by);
      end if;
      update v2.behavior_records br set note = coalesce(br.note,'')||
          ' · ومعها تأخّرٌ '||v2.ar_num(coalesce(st.minutes_from_assembly,0))||' دقيقة (رصدٌ آليٌّ عند الإقفال)'
        where br.student_id=st.student_id and br.problem_id=v_prob
          and br.status<>'voided' and br.created_at::date=current_date
          and coalesce(br.note,'') not like '%رصدٌ آليٌّ عند الإقفال%';
      insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,ref_table,ref_id)
      values (p_school,'late_report',p_date,st.student_id,'تأخر صباحي',
        'حضر ابنكم اليوم متأخراً '||coalesce(st.minutes_from_assembly,0)||' دقيقة عن الاصطفاف الصباحي.',
        'attendance',st.id) returning id into v_ev;
      n_ev := n_ev + 1;
      for g in select id from v2.guardians where student_id=st.student_id loop
        insert into v2.event_deliveries(event_id,channel,to_guardian) values (v_ev,'guardian_portal',g.id),(v_ev,'whatsapp',g.id);
      end loop;
    end if;

    if st.assembly_state in ('missed_inside','late_inside') then
      select id into v_prob from v2.conduct_problems where stage_scope=v_scope and mode='onsite' and target='general'
        and text_ar like case st.assembly_state when 'missed_inside' then 'عدم حضور الاصطفاف%' else 'التأخر عن الاصطفاف%' end limit 1;
      if v_prob is not null
         and not exists (select 1 from v2.behavior_records br
                          where br.student_id=st.student_id and br.problem_id=v_prob
                            and br.status<>'voided' and br.created_at::date=current_date) then
        perform v2.fn_record_behavior(st.student_id,v_prob,st.term_no,null,'الاصطفاف',
          'رصد آلي عند إقفال اليوم',null,false,false,false,false,p_by);
      end if;
    end if;
  end loop;

  for r in select pa.* from v2.period_attendance pa
            where pa.school_id=p_school and pa.on_date=p_date and pa.state='absent' loop
    select id into v_prob from v2.conduct_problems where stage_scope=v_scope and mode='onsite'
      and target='general' and text_ar like 'عدم حضور الحصة الدراسية%' limit 1;
    if v_prob is not null then
      perform v2.fn_record_behavior(r.student_id,v_prob,r.term_no,r.period_no,'الفصل',
        'غياب عن الحصة '||r.period_no||' بلا إذن — رصد آلي عند إقفال اليوم',null,false,false,false,false,p_by);
    end if;
  end loop;

  for r in select pa.* from v2.period_attendance pa
            where pa.school_id=p_school and pa.on_date=p_date and pa.state='late' loop
    select id into v_prob from v2.conduct_problems where stage_scope=v_scope and mode='onsite'
      and target='general' and text_ar like 'التأخر في الدخول إلى الحصص%' limit 1;
    if v_prob is not null then
      perform v2.fn_record_behavior(r.student_id,v_prob,r.term_no,r.period_no,'الفصل',
        'تأخر عن الحصة '||r.period_no||coalesce(' ('||r.minutes_late||' دقيقة)','')||' — رصد آلي عند إقفال اليوم',
        null,false,false,false,false,p_by);
    end if;
  end loop;

  insert into v2.day_closures(school_id,on_date,closed_by,students_n,absent_n,late_n,derived_n)
  values (p_school,p_date,p_by,(select count(*) from v2.attendance where school_id=p_school and on_date=p_date),
          n_abs,n_late,n_der)
  on conflict (school_id,on_date) do update
    set reclosed_at=now(), absent_n=excluded.absent_n, late_n=excluded.late_n, derived_n=excluded.derived_n;

  return query select n_enr,
    (select count(*)::int from v2.attendance where school_id=p_school and on_date=p_date),
    n_abs, n_late, n_der, n_none, n_ev;
end $function$
;
