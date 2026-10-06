-- v2.fn_reopen_day(p_school uuid, p_date date, p_reason text, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5cf986483eea38e9e5c78503e00b3489
CREATE OR REPLACE FUNCTION v2.fn_reopen_day(p_school uuid, p_date date, p_reason text, p_by uuid DEFAULT NULL::uuid)
 RETURNS TABLE("رصدات_سلوكية_نُقضت" integer, "حالات_غياب_نُقضت" integer, "حسومات_رُدّت" integer, "أحداث_أُلغيت" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n_beh int:=0; n_case int:=0; n_ded int:=0; n_ev int:=0; v_year uuid;
begin
  perform v2.assert_role(array['deputy_students','deputy'],'إعادة فتح اليوم');
  if btrim(coalesce(p_reason,''))='' then raise exception 'لا يُعاد فتح يوم بلا سبب مكتوب'; end if;
  if not exists (select 1 from v2.day_closures where school_id=p_school and on_date=p_date) then
    raise exception 'يوم % لم يُقفل أصلاً', p_date; end if;

  select id into v_year from v2.academic_years where school_id=p_school and is_current limit 1;

  update v2.behavior_records r set status='voided', voided_by=p_by,
    void_reason='نُقض بإعادة فتح يوم '||p_date||': '||p_reason
   where r.school_id=p_school and r.occurred_on=p_date and r.status='open'
     and r.note like '%رصد آلي عند إقفال اليوم%';
  get diagnostics n_beh = row_count;

  insert into v2.behavior_ledger(school_id,year_id,term_no,student_id,kind,points,record_id,reason,by_person)
  select r.school_id,r.year_id,r.term_no,r.student_id,'veto',-l.points,r.id,
    'نقض الحسم بإعادة فتح يوم '||p_date||': '||p_reason, p_by
  from v2.behavior_records r join v2.behavior_ledger l on l.record_id=r.id and l.kind='deduction'
  where r.school_id=p_school and r.occurred_on=p_date and r.status='voided';

  insert into v2.attendance_ledger(school_id,year_id,student_id,kind,points,on_date,reason,by_person)
  select l.school_id,l.year_id,l.student_id,'restore',-l.points,l.on_date,
    'ردّ الحسم بإعادة فتح يوم '||p_date||': '||p_reason, p_by
  from v2.attendance_ledger l
  where l.school_id=p_school and l.on_date=p_date and l.kind='deduction'
    and not exists (select 1 from v2.attendance_ledger x where x.student_id=l.student_id
                    and x.on_date=l.on_date and x.kind='restore');
  get diagnostics n_ded = row_count;

  update v2.absence_cases c set status='closed',
    halt_reason='نُقضت بإعادة فتح يوم '||p_date||': '||p_reason
   where c.school_id=p_school and c.triggered_on=p_date and c.status='open';
  get diagnostics n_case = row_count;

  update v2.event_deliveries d set status='cancelled',
    cancel_reason='أُعيد فتح اليوم: '||p_reason
   from v2.events e where d.event_id=e.id and e.school_id=p_school and e.on_date=p_date
     and d.status in ('queued','sent','delivered');
  get diagnostics n_ev = row_count;

  update v2.attendance set day_status='provisional' where school_id=p_school and on_date=p_date;
  update v2.day_closures set reopened_at=now(), reopened_by=p_by, reopen_reason=p_reason
   where school_id=p_school and on_date=p_date;

  insert into v2.day_reversals(school_id,on_date,kind,reason,by_person,reverted)
  values (p_school,p_date,'reopen',p_reason,p_by,
    jsonb_build_object('رصدات_سلوكية',n_beh,'حالات_غياب',n_case,'حسومات',n_ded,'أحداث',n_ev));

  return query select n_beh,n_case,n_ded,n_ev;
end $function$
;
