-- v2.trg_mark_test()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 830a5ad31a830e03b3bb77fe46a2aaba
CREATE OR REPLACE FUNCTION v2.trg_mark_test()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; j jsonb;
begin
  j := to_jsonb(new);
  sc := case when j ? 'school_id' and j->>'school_id' is not null then (j->>'school_id')::uuid
        when j ? 'student_id' and j->>'student_id' is not null then
          (select e.school_id from v2.enrolments e
            where e.student_id = (j->>'student_id')::uuid and e.status='active' limit 1)
        else null end;
  new.is_test := v2.is_test_school(sc);
  return new;
end $function$
;
