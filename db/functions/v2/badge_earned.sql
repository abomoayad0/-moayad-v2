-- v2.badge_earned(p_school uuid, p_student uuid, p_code text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3161bdecf7c01a7bfb740d71bd9e9fc7
CREATE OR REPLACE FUNCTION v2.badge_earned(p_school uuid, p_student uuid, p_code text)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE
AS $function$
declare b v2.loyalty_badges; d int; yr uuid;
begin
  b := v2.badge_of(p_school, p_code);
  if b.code is null or b.rule_kind = 'manual' then return false; end if;
  select id into yr from v2.academic_years where school_id=p_school and is_current limit 1;

  if b.rule_kind = 'no_late_month' then
    d := (v2.rule_n(p_school,'badge_no_late_days'))::int;
    return exists (select 1 from v2.attendance a
                    where a.student_id=p_student and a.on_date >= current_date - d)
       and not exists (select 1 from v2.attendance a
                    where a.student_id=p_student and a.on_date >= current_date - d
                      and a.state = 'late');
  elsif b.rule_kind = 'distinct_sources' then
    return (select count(distinct l.source_code) from v2.loyalty_ledger l
             where l.student_id=p_student and l.kind='earn' and l.voided_at is null
               and (yr is null or l.year_id = yr)) >= coalesce(b.rule_n,6);
  elsif b.rule_kind = 'balance_at_least' then
    return v2.loyalty_balance(p_school, p_student) >= coalesce(b.rule_n,0);
  end if;
  return false;
end $function$
;
