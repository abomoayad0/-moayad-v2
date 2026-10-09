-- public.v2_mail_register(p_from_entity text, p_subject text, p_body text, p_ref_no text, p_received_on date, p_doc_date date, p_secrecy text, p_source text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9f10497b699703150f673a8a6c2cae4b
CREATE OR REPLACE FUNCTION public.v2_mail_register(p_from_entity text, p_subject text, p_body text DEFAULT NULL::text, p_ref_no text DEFAULT NULL::text, p_received_on date DEFAULT CURRENT_DATE, p_doc_date date DEFAULT NULL::date, p_secrecy text DEFAULT 'عادي'::text, p_source text DEFAULT 'school_inbox'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; mid uuid; n integer;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'تسجيل وارد');
  sc := v2.acting_school();
  if sc is null then raise exception 'لم تُعرف مدرستُك — فلا يُعرف سجلُّ الوارد'; end if;
  perform v2.assert_my_school(sc,'تسجيل وارد');
  if coalesce(btrim(p_from_entity),'') = '' then raise exception 'الجهةُ الواردُ منها لا تُترك فارغةً'; end if;
  if coalesce(btrim(p_subject),'') = '' then raise exception 'موضوعُ الوارد لا يُترك فارغًا'; end if;
  if p_received_on > current_date then raise exception 'لا يُسجَّل واردٌ بتاريخٍ لم يأتِ'; end if;
  if p_secrecy <> 'عادي' then
    perform v2.assert_role(array['principal','deputy'],'تسجيل واردٍ '||p_secrecy);
  end if;

  select id into yr from v2.academic_years where school_id = sc and is_current limit 1;
  n := v2.next_incoming_serial(sc, yr);

  insert into v2.incoming_mail(school_id,year_id,serial_no,ref_no,from_entity,
      subject_ar,body_ar,received_on_g,received_on_h,doc_date_g,doc_date_h,
      secrecy,received_by,status,source)
  values (sc,yr,n,nullif(btrim(p_ref_no),''),btrim(p_from_entity),
      btrim(p_subject),p_body,p_received_on,v2.fn_to_hijri(p_received_on),
      p_doc_date, case when p_doc_date is null then null else v2.fn_to_hijri(p_doc_date) end,
      p_secrecy,v2.current_person(),'new',p_source)
  returning id into mid;

  perform v2.log_action(sc,null,'mail_register','سُجّل واردٌ جديد','incoming_mail',mid,
    jsonb_build_object('serial',n,'from',btrim(p_from_entity)));

  return jsonb_build_object('ok',true,'mail',mid,'serial',n,
    'serial_ar','الواردُ رقم '||v2.ar_num(n),
    'received_ar',v2.fn_to_hijri(p_received_on)||' هـ',
    'note_ar','سُجّل الواردُ رقم '||v2.ar_num(n)||' — وبقي توجيهُه، '||
      'فما لم يُوجَّه لا يُتابعه أحد');
end $function$
;
