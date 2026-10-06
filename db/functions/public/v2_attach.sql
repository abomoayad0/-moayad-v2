-- public.v2_attach(p_student uuid, p_kind text, p_file_name text, p_storage_path text, p_mime text, p_size_kb integer, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cff90f650f9cb700a725aded592a85e0
CREATE OR REPLACE FUNCTION public.v2_attach(p_student uuid, p_kind text, p_file_name text, p_storage_path text, p_mime text DEFAULT NULL::text, p_size_kb integer DEFAULT NULL::integer, p_note text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; gid uuid; v uuid; st text; m text; d text; h text; c text;
begin
  if p_kind not in ('excuse','pledge','medical','other') then
    raise exception 'نوع مرفق غير معروف: %', p_kind; end if;
  select id into gid from v2.guardians where user_id=auth.uid() and portal_active and student_id=p_student;
  if gid is null then perform v2.assert_my_student(p_student,'رفع مرفق');
  else perform v2.assert_my_child(p_student,'رفع مرفق'); end if;
  select e.school_id into sc from v2.enrolments e where e.student_id=p_student and e.status='active' limit 1;
  insert into v2.attachments(school_id,student_id,guardian_id,kind,file_name,mime,size_kb,
    storage_path,note,uploaded_by,uploaded_role)
  values (sc,p_student,gid,p_kind,p_file_name,p_mime,p_size_kb,p_storage_path,p_note,
    v2.current_person(), coalesce(v2.role_ar(v2.my_role()),'ولي الأمر'))
  returning id into v;
  return v;
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_attach','المرفقات','رفع مرفق',
    jsonb_build_object('student',p_student,'kind',p_kind,'file',p_file_name),st,d,h,c,'bridge',
    case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
