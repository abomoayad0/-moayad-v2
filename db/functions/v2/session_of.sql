-- v2.session_of(p_school uuid, p_person uuid, p_date date, p_period smallint, p_section uuid, p_create boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a0212e8f166d3f518001f433f71a3321
CREATE OR REPLACE FUNCTION v2.session_of(p_school uuid, p_person uuid, p_date date, p_period smallint, p_section uuid DEFAULT NULL::uuid, p_create boolean DEFAULT true)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare e record; sid uuid; v_late int; v_start time;
        v_now time := (now() at time zone 'Asia/Riyadh')::time;
begin
  select ep.slot, ep.period_no, ep.section_id, ep.subject_ar, ep.basis, ep.from_ar
    into e
    from v2.effective_periods(p_school, p_person, p_date) ep
   where ep.period_no = p_period
     and (p_section is null or ep.section_id = p_section)
   limit 1;
  if e.period_no is null then return null; end if;

  select id into sid from v2.class_sessions
   where school_id=p_school and on_date=p_date and period_no=p_period
     and section_id=e.section_id;
  if sid is not null or not p_create then return sid; end if;

  select ps.starts_at into v_start from v2.period_slots ps
   where ps.school_id=p_school and ps.period_no=p_period;
  v_late := case when p_date = current_date and v_start is not null
                 then greatest(0, (extract(epoch from (v_now - v_start))/60)::int) end;

  insert into v2.class_sessions (school_id, year_id, term_no, on_date, period_no,
      section_id, slot_id, person_id, basis, from_ar, subject_ar,
      opened_by, late_min, is_test)
  values (p_school,
      (select y.id from v2.academic_years y where y.school_id=p_school and y.is_current limit 1),
      v2.fn_term_of(p_school, p_date), p_date, p_period, e.section_id, e.slot,
      p_person, e.basis, e.from_ar, e.subject_ar,
      v2.current_person(), v_late,
      coalesce((select s.test_mode from v2.schools s where s.id=p_school), false))
  on conflict (school_id, on_date, period_no, section_id) do nothing
  returning id into sid;

  if sid is null then
    select id into sid from v2.class_sessions
     where school_id=p_school and on_date=p_date and period_no=p_period
       and section_id=e.section_id;
  end if;
  return sid;
end $function$
;
