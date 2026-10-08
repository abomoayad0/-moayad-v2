-- public.v2_outgoing_attach(p_mail uuid, p_kind text, p_name text, p_url text, p_file_ref text, p_barcode text, p_form_entry uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cdaded3f6525a48e9569d7bfa2dcd982
CREATE OR REPLACE FUNCTION public.v2_outgoing_attach(p_mail uuid, p_kind text DEFAULT 'file'::text, p_name text DEFAULT NULL::text, p_url text DEFAULT NULL::text, p_file_ref text DEFAULT NULL::text, p_barcode text DEFAULT NULL::text, p_form_entry uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'],'إرفاق على الصادر');
  select * into m from v2.outgoing_mail where id = p_mail;
  if m.id is null then raise exception 'الخطابُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'إرفاق على الصادر');
  if m.status in ('closed','cancelled') then
    raise exception 'لا يُرفَق على خطابٍ % شيءٌ',
      case when m.status='closed' then 'مُقفل' else 'ملغًى' end;
  end if;
  if coalesce(p_url,p_file_ref,p_barcode,p_form_entry::text) is null then
    raise exception 'المرفقُ بلا ملفٍّ ولا رابطٍ ولا باركودٍ ولا نموذجٍ — فلا شيءَ يُرفَق';
  end if;

  insert into v2.outgoing_attachments(mail_id,kind,name_ar,url,file_ref,barcode_val,form_entry)
  values (p_mail,p_kind,p_name,p_url,p_file_ref,p_barcode,p_form_entry);

  return v2.outgoing_card(p_mail) || jsonb_build_object('ok', true);
end $function$
;
