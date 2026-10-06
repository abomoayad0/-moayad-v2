-- public.v2_form_void(p_entry uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3792c273cd7ba5ea9af4559f7c726157
CREATE OR REPLACE FUNCTION public.v2_form_void(p_entry uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid;
begin
  if btrim(coalesce(p_reason,''))='' then raise exception 'لا يُلغى نموذج بلا سبب مكتوب'; end if;
  select school_id into sc from v2.form_entries where id=p_entry;
  perform v2.assert_my_school(sc,'إلغاء نموذج');
  perform v2.assert_role(array['deputy_students','deputy','principal'],'إلغاء النماذج المعتمدة');
  update v2.form_entries set status='void', void_reason=p_reason, updated_at=now()
   where id=p_entry and status<>'void';
  if not found then raise exception 'النموذج مُلغًى سلفًا'; end if;
end $function$
;
