-- public.v2_outgoing_one(p_mail uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6ab439d9295375ea1c99a6693a95d78c
CREATE OR REPLACE FUNCTION public.v2_outgoing_one(p_mail uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare m record;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students','counselor'],'قراءة الصادر');
  select * into m from v2.outgoing_mail where id = p_mail;
  if m.id is null then raise exception 'الخطابُ غيرُ موجود'; end if;
  perform v2.assert_my_school(m.school_id,'قراءة الصادر');
  if m.secrecy <> 'عادي' then
    perform v2.assert_role(array['principal','deputy'],'قراءة صادرٍ '||m.secrecy);
  end if;
  return v2.outgoing_card(p_mail);
end $function$
;
