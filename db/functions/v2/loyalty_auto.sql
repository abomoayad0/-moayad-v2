-- v2.loyalty_auto(p_school uuid, p_student uuid, p_source text, p_by uuid, p_reason text, p_period smallint, p_on_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1ff294353cb66f80943d3f8c28f7abd8
CREATE OR REPLACE FUNCTION v2.loyalty_auto(p_school uuid, p_student uuid, p_source text, p_by uuid, p_reason text DEFAULT NULL::text, p_period smallint DEFAULT NULL::smallint, p_on_date date DEFAULT CURRENT_DATE)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare s v2.loyalty_sources; cap int; used int; bal int; yr uuid; tm smallint; give int;
begin
  s := v2.loyalty_source(p_school, p_source);
  if s.id is null or s.auto_kind <> 'engine' then return 0; end if;
  if s.points > v2.rule_n(p_school,'loyalty_max_per_act') then return 0; end if;

  cap  := coalesce(s.week_cap, v2.rule_n(p_school,'loyalty_week_cap_default'));
  used := v2.loyalty_week_used(p_school, p_student, s.code, p_on_date);
  give := least(s.points, greatest(cap - used, 0));
  if give <= 0 then return 0; end if;

  if s.kind = 'deduct' then
    bal := v2.loyalty_balance(p_school, p_student);
    if v2.rule_n(p_school,'loyalty_allow_negative') = 0 and bal - give < 0 then return 0; end if;
  end if;

  select id into yr from v2.academic_years where school_id=p_school and is_current limit 1;
  tm := v2.fn_term_of(p_school, p_on_date);

  insert into v2.loyalty_ledger (school_id,year_id,term_no,student_id,kind,source_code,points,
      reason_ar,on_date,period_no,by_person,by_role_ar)
  values (p_school,yr,tm,p_student,s.kind,s.code,give,
      coalesce(nullif(btrim(coalesce(p_reason,'')),''),'مُنحت آليًّا'),
      p_on_date,p_period,p_by,'المحرّك الآليّ')
  on conflict do nothing;
  return give;
exception when others then
  return 0;   -- المانحُ الآليُّ لا يُسقط عملَ المعلّم بحالٍ
end $function$
;
