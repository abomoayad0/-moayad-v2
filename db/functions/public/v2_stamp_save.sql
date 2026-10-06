-- public.v2_stamp_save(p_school uuid, p_image_ref text, p_valid_from date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 86b631a954b0f89e5a212b79c2b4dec7
CREATE OR REPLACE FUNCTION public.v2_stamp_save(p_school uuid, p_image_ref text, p_valid_from date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid;
begin
  perform v2.assert_role(array['principal'],'ختمَ المدرسة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_image_ref,''))='' then raise exception 'ارفع صورةَ الختم أوّلًا'; end if;
  -- 🔒 الختمُ السابقُ يُنهى سريانُه ولا يُمحى — فما خُتم به يبقى معروفًا
  update v2.stamps set valid_to = coalesce(p_valid_from,current_date) - 1
   where school_id=p_school and valid_to is null;
  insert into v2.stamps(school_id,image_ref,valid_from)
  values (p_school,btrim(p_image_ref),coalesce(p_valid_from,current_date))
  returning id into nid;
  return jsonb_build_object('ok',true,'stamp',nid,
    'note','وأُنهي سريانُ الختم السابق — ولم يُمحَ');
end $function$
;
