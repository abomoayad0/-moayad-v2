-- v2.fn_accept_excuse(p_claim uuid, p_by uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9e7b272cc12ec09725852988a3bf053c
CREATE OR REPLACE FUNCTION v2.fn_accept_excuse(p_claim uuid, p_by uuid DEFAULT NULL::uuid, p_note text DEFAULT NULL::text)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; v_year uuid; v_school uuid; n int := 0; d date;
begin
  select * into c from v2.absence_excuse_claims where id=p_claim;
  if c.id is null then raise exception 'العذر غير موجود'; end if;
  select e.school_id, e.year_id into v_school, v_year
   from v2.enrolments e where e.student_id=c.student_id and e.status='active'
   order by e.created_at desc limit 1;

  update v2.absence_excuse_claims
     set decision='accepted', decided_by=p_by, decided_at=now(), decision_note=p_note
   where id=p_claim;

  for d in select a.on_date from v2.attendance a
           where a.student_id=c.student_id and a.state='absent'
             and a.on_date between c.from_date and c.to_date loop
    if exists (select 1 from v2.attendance_ledger l
               where l.student_id=c.student_id and l.year_id=v_year and l.kind='deduction' and l.on_date=d)
       and not exists (select 1 from v2.attendance_ledger l
               where l.student_id=c.student_id and l.year_id=v_year and l.kind='restore' and l.on_date=d) then
      insert into v2.attendance_ledger(school_id,year_id,student_id,kind,points,on_date,reason,by_person)
      values (v_school,v_year,c.student_id,'restore',1,d,
        'ردّ درجة بعد قبول العذر عن يوم ('||d||') — عدم التأثير على درجة المواظبة في حال تقديم عذر مقبول · م35 بند 7 · CONDUCT-1447-OFF ص51', p_by);
      n := n + 1;
    end if;
  end loop;
  return n;
end $function$
;
