-- v2.cover_rules_of(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 937e78e0864781d0e6aef29e7ef467d5
CREATE OR REPLACE FUNCTION v2.cover_rules_of(p_school uuid)
 RETURNS v2.cover_rules
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare x v2.cover_rules;
begin
  select * into x from v2.cover_rules where school_id = p_school;
  if x.school_id is null then
    x.school_id := p_school; x.auto_on := true; x.max_per_day := 2;
    x.prefer_same_subject := false; x.allow_teaching_free := false; x.updated_at := now();
  end if;
  return x;
end $function$
;
