-- v2.pairing_of(p_school uuid, p_grade smallint, p_subject text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ffb346ab9af04b73c7a1b49ac991c196
CREATE OR REPLACE FUNCTION v2.pairing_of(p_school uuid, p_grade smallint, p_subject text)
 RETURNS v2.subject_pairing
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare x v2.subject_pairing;
begin
  select * into x from v2.subject_pairing s
   where s.school_id = p_school and s.subject_ar = p_subject
     and (s.grade is null or s.grade = p_grade)
   order by (case when s.grade is not null then 1 else 0 end) desc limit 1;
  if x.id is null then
    x.school_id := p_school; x.grade := p_grade; x.subject_ar := p_subject;
    x.mode := 'split'; x.max_per_day := 1;
  end if;
  return x;
end $function$
;
