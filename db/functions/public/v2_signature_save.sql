-- public.v2_signature_save(p_school uuid, p_person uuid, p_image_ref text, p_valid_from date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e9684760e82bea9adce5867324861b3c
CREATE OR REPLACE FUNCTION public.v2_signature_save(p_school uuid, p_person uuid, p_image_ref text, p_valid_from date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; me uuid;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  me := v2.current_person();
  -- 🔒 التوقيعُ شخصيّ: صاحبُه أو المديرُ وحدَهما
  if p_person <> me then
    perform v2.assert_role(array['principal'],'رفعَ توقيعِ غيرك'); end if;
  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_person and a.school_id=p_school and a.ended_on is null) then
    raise exception 'هذا المنسوب ليس من منسوبي مدرستك'; end if;
  if btrim(coalesce(p_image_ref,''))='' then raise exception 'ارفع صورةَ التوقيع أوّلًا'; end if;

  update v2.signatures set valid_to = coalesce(p_valid_from,current_date) - 1
   where person_id=p_person and valid_to is null;
  insert into v2.signatures(person_id,image_ref,valid_from)
  values (p_person,btrim(p_image_ref),coalesce(p_valid_from,current_date))
  returning id into nid;
  return jsonb_build_object('ok',true,'signature',nid);
end $function$
;
