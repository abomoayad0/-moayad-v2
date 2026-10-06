-- v2.fn_log_incoming(p_school uuid, p_from text, p_subject text, p_received date, p_body text, p_ref text, p_secrecy text, p_doc_date date, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 8b0d8748890159a875ab634555aef1c6
CREATE OR REPLACE FUNCTION v2.fn_log_incoming(p_school uuid, p_from text, p_subject text, p_received date DEFAULT NULL::date, p_body text DEFAULT NULL::text, p_ref text DEFAULT NULL::text, p_secrecy text DEFAULT 'عادي'::text, p_doc_date date DEFAULT NULL::date, p_by uuid DEFAULT NULL::uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare v_year uuid; v_id uuid; v_no int; d date := coalesce(p_received, current_date);
begin
  select id into v_year from v2.academic_years where school_id=p_school and is_current limit 1;
  select coalesce(max(serial_no),0)+1 into v_no from v2.incoming_mail
   where school_id=p_school and year_id is not distinct from v_year;
  insert into v2.incoming_mail(school_id,year_id,serial_no,ref_no,from_entity,subject_ar,body_ar,
      received_on_g,received_on_h,doc_date_g,doc_date_h,secrecy,received_by)
  values (p_school,v_year,v_no,p_ref,p_from,p_subject,p_body,
      d, v2.fn_to_hijri(d), p_doc_date, v2.fn_to_hijri(p_doc_date), p_secrecy, p_by)
  returning id into v_id;
  return v_id;
end $function$
;
