-- v2.fn_open_counsel_case(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a88f4d48d2fa55a70eedd2eb5ef14059
CREATE OR REPLACE FUNCTION v2.fn_open_counsel_case(p_record uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; cid uuid;
begin
  select * into r from v2.behavior_records where id = p_record;
  if r.id is null then return null; end if;
  select id into cid from v2.counsel_cases
   where student_id=r.student_id and problem_id=r.problem_id and year_id=r.year_id;
  if cid is not null then return cid; end if;
  insert into v2.counsel_cases(school_id,student_id,record_id,problem_id,year_id,term_no,
      opened_on,is_test)
  values (r.school_id,r.student_id,r.id,r.problem_id,r.year_id,r.term_no,
      current_date, coalesce(r.is_test,false))
  returning id into cid;
  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (r.school_id,'case_study',current_date,r.student_id,
      'أُحيل الملفُّ إلى الموجّه الطلابيّ لدراسة حالته',
      'الإجراءُ الثالث — قواعد السلوك والمواظبة ص٢٠',
      'counsel_cases',cid,'counselor_only',coalesce(r.is_test,false));
  return cid;
end $function$
;
