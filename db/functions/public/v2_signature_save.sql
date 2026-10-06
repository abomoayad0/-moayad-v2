-- public.v2_signature_save(p_school uuid, p_person uuid, p_image_ref text, p_valid_from date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e9b0f879406e285eea96214fc5b203d1
CREATE OR REPLACE FUNCTION public.v2_signature_save(p_school uuid, p_person uuid, p_image_ref text, p_valid_from date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; me uuid; d date; pth text;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  me := v2.current_person();
  -- 🔒 التوقيعُ شخصيٌّ لا يُرفع عن أحد — ولو كان المدير
  if p_person is distinct from me then
    raise exception 'التوقيعُ شخصيّ — يرفعه صاحبُه بحسابه، ولا يُرفع عنه'; end if;
  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_person and a.school_id=p_school and a.ended_on is null) then
    raise exception 'هذا المنسوب ليس من منسوبي مدرستك'; end if;
  pth := btrim(coalesce(p_image_ref,''));
  if pth='' then raise exception 'ارفع صورةَ التوقيع أوّلًا'; end if;
  if pth not like 'brand/'||p_school||'/sign/'||p_person||'/%' then
    raise exception 'الصورةُ ليست في مجلّد توقيعك — ارفعها إلى ما يرجعه v2_brand_upload_path'; end if;
  if not exists (select 1 from storage.objects
                  where bucket_id='v2-attachments' and name=pth) then
    raise exception 'لم يُعثر على الصورة في المخزن — ارفعها أوّلًا'; end if;

  d := coalesce(p_valid_from,current_date);
  if exists (select 1 from v2.signatures where person_id=p_person and valid_from=d) then
    raise exception 'سُجّل توقيعٌ بهذا التاريخ سلفًا — اختر تاريخًا آخر'; end if;
  update v2.signatures set valid_to = d - 1
   where person_id=p_person and valid_to is null and valid_from < d;
  insert into v2.signatures(person_id,image_ref,valid_from)
  values (p_person,pth,d) returning id into nid;
  return jsonb_build_object('ok',true,'signature',nid);
end $function$
;
