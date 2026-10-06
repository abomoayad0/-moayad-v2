-- public.v2_stamp_save(p_school uuid, p_image_ref text, p_valid_from date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 d2a6749897fea3f0292b193178c85295
CREATE OR REPLACE FUNCTION public.v2_stamp_save(p_school uuid, p_image_ref text, p_valid_from date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; d date;
begin
  perform v2.assert_role(array['principal'],'ختمَ المدرسة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_image_ref,''))='' then raise exception 'ارفع صورةَ الختم أوّلًا'; end if;
  if not v2.brand_path_allows(btrim(p_image_ref),false) then
    raise exception 'الصورةُ ليست في مسار مدرستك — ارفعها إلى المسار الذي يرجعه v2_brand_upload_path'; end if;
  d := coalesce(p_valid_from,current_date);
  if exists (select 1 from v2.stamps where school_id=p_school and valid_from=d) then
    raise exception 'سُجّل ختمٌ بهذا التاريخ سلفًا — اختر تاريخًا آخر'; end if;
  update v2.stamps set valid_to = d - 1
   where school_id=p_school and valid_to is null and valid_from < d;
  insert into v2.stamps(school_id,image_ref,valid_from)
  values (p_school,btrim(p_image_ref),d) returning id into nid;
  return jsonb_build_object('ok',true,'stamp',nid,
    'note','وأُنهي سريانُ الختم السابق — ولم يُمحَ');
end $function$
;
