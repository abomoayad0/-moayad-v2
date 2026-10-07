-- public.v2_message_template_save(p_school uuid, p_key text, p_body text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 197af7dd925298ca9359dbdacd3660d8
CREATE OR REPLACE FUNCTION public.v2_message_template_save(p_school uuid, p_key text, p_body text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'ضبطَ قوالب الرسائل');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_body,''))='' then raise exception 'اكتب نصَّ الرسالة'; end if;
  if p_body not like '%{الطالب}%' then
    raise exception 'لا بدّ أن يحمل القالبُ {الطالب} على الأقلّ'; end if;
  insert into v2.message_templates(school_id,key,body_ar)
  values (p_school,coalesce(p_key,'guardian_notice'),btrim(p_body))
  on conflict (school_id,key,step_no) do update set body_ar=excluded.body_ar, active=true;
  return jsonb_build_object('ok',true);
end $function$
;
