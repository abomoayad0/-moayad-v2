-- v2.fn_form_deliver(p_entry uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7fe17e70a7ecff198b71cfbe2b3aadb1
CREATE OR REPLACE FUNCTION v2.fn_form_deliver(p_entry uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare e record; k text; n int := 0; g record; sc uuid;
begin
  select * into e from v2.form_entries where id=p_entry;
  if e.status <> 'final' then return 0; end if;
  foreach k in array (select goes_to from v2.official_forms where form_no=e.form_no) loop
    if k='guardian' and e.student_id is not null then
      for g in select id from v2.guardians where student_id=e.student_id loop
        insert into v2.form_inbox(entry_id,to_kind,guardian_id,student_id)
        select p_entry,'guardian',g.id,e.student_id
        where not exists (select 1 from v2.form_inbox x where x.entry_id=p_entry and x.guardian_id=g.id);
        n := n + 1;
      end loop;
    elsif k='student' and e.student_id is not null then
      insert into v2.form_inbox(entry_id,to_kind,student_id) values (p_entry,'student',e.student_id);
      n := n + 1;
    elsif k='counselor' then
      insert into v2.form_inbox(entry_id,to_kind,person_id,student_id)
      select p_entry,'counselor',a.person_id,e.student_id from v2.assignments a
       where a.school_id=e.school_id and a.post_key='counselor' and a.ended_on is null limit 1;
      n := n + 1;
    elsif k='committee' then
      insert into v2.form_inbox(entry_id,to_kind,person_id,student_id)
      select p_entry,'committee',a.person_id,e.student_id from v2.assignments a
       where a.school_id=e.school_id and a.post_key in ('deputy_students','principal') and a.ended_on is null;
      n := n + 1;
    end if;
  end loop;
  return n;
end $function$
;
