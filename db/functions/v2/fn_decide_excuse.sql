-- v2.fn_decide_excuse(p_claim uuid, p_accept boolean, p_by uuid, p_note text, p_principal_ext boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 637d1e1e879b05e92bae2c449c26341c
CREATE OR REPLACE FUNCTION v2.fn_decide_excuse(p_claim uuid, p_accept boolean, p_by uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text, p_principal_ext boolean DEFAULT false)
 RETURNS TABLE("أيام_الغياب" integer, "درجات_رُدّت" integer, "حالات_أُوقف_تصعيدها" integer)
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; v_year uuid; v_school uuid; d date; n_days int:=0; n_back int:=0; n_halt int:=0; v_ev uuid; g record;
begin
  select * into c from v2.absence_excuse_claims where id=p_claim;
  if c.id is null then raise exception 'العذر غير موجود'; end if;
  if c.decision <> 'pending' then raise exception 'بُتّ في هذا العذر سلفاً: %', c.decision; end if;
  if not p_accept and btrim(coalesce(p_note,''))='' then
    raise exception 'ردّ العذر لا يقع بلا سبب مكتوب'; end if;

  select e.school_id, e.year_id into v_school, v_year from v2.enrolments e
   where e.student_id=c.student_id and e.status='active' order by e.created_at desc limit 1;

  update v2.absence_excuse_claims
     set decision = case when p_accept then 'accepted' else 'rejected' end,
         decided_by=p_by, decided_at=now(), decision_note=p_note, principal_extension=p_principal_ext
   where id=p_claim;

  if p_accept then
    for d in select a.on_date from v2.attendance a
             where a.student_id=c.student_id and a.state='absent'
               and a.on_date between c.from_date and c.to_date loop
      n_days := n_days + 1;
      if exists (select 1 from v2.attendance_ledger l where l.student_id=c.student_id
                   and l.year_id=v_year and l.kind='deduction' and l.on_date=d)
         and not exists (select 1 from v2.attendance_ledger l where l.student_id=c.student_id
                   and l.year_id=v_year and l.kind='restore' and l.on_date=d) then
        insert into v2.attendance_ledger(school_id,year_id,student_id,kind,points,on_date,reason,by_person)
        values (v_school,v_year,c.student_id,'restore',1,d,
          'ردّ درجة بعد قبول العذر عن يوم ('||d||') — ' || v2.cite('excuse.no_effect') || '. واليوم يبقى غياباً في السجل والعدّ تراكمي.', p_by);
        n_back := n_back + 1;
      end if;
    end loop;

    -- الحالات المفتوحة بلا عذر: يُوقف تصعيدها ولا تُحذف
    update v2.absence_cases ac set escalation_halted=true,
      halt_reason='أُوقف التصعيد بقبول عذر عن '||c.from_date||' إلى '||c.to_date||' — والحالة ومهامها المنفَّذة تبقى في السجل، والغياب لا يُمحى.'
     where ac.student_id=c.student_id and ac.year_id=v_year and ac.excused=false
       and ac.status='open' and ac.escalation_halted=false;
    get diagnostics n_halt = row_count;

    update v2.absence_tasks t set status='skipped',
      skip_reason='أُوقف التصعيد بقبول عذر مقبول — م35 بند 7'
     from v2.absence_cases ac
     where t.case_id=ac.id and ac.student_id=c.student_id and ac.escalation_halted
       and t.status='open';

    insert into v2.day_reversals(school_id,on_date,kind,reason,by_person,reverted)
    values (v_school,c.from_date,'excuse_accepted',
      'قُبل عذر عن الفترة '||c.from_date||'–'||c.to_date||coalesce(' · '||p_note,''),p_by,
      jsonb_build_object('أيام',n_days,'درجات_رُدّت',n_back,'حالات_أُوقف_تصعيدها',n_halt));
  end if;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,ref_table,ref_id)
  values (v_school,'excuse_decided',current_date,c.student_id,
    case when p_accept then 'قُبل العذر' else 'رُدّ العذر' end,
    case when p_accept then 'قُبل عذر الغياب عن '||c.from_date||' إلى '||c.to_date||
         '. ورُدّت '||n_back||' درجة مواظبة. وأيام الغياب تبقى في السجل — العدّ تراكمي ولا يُمحى.'
         else 'رُدّ عذر الغياب عن '||c.from_date||' إلى '||c.to_date||'. السبب: '||p_note end,
    'absence_excuse_claims',p_claim) returning id into v_ev;
  for g in select id from v2.guardians where student_id=c.student_id loop
    insert into v2.event_deliveries(event_id,channel,to_guardian) values (v_ev,'guardian_portal',g.id),(v_ev,'whatsapp',g.id);
  end loop;

  return query select n_days, n_back, n_halt;
end $function$
;
