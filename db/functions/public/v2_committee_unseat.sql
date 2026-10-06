-- public.v2_committee_unseat(p_school uuid, p_committee text, p_person uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 07bd09281bd0c6e9cc0e32af28144137
CREATE OR REPLACE FUNCTION public.v2_committee_unseat(p_school uuid, p_committee text, p_person uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_students','deputy'],'تشكيل اللجان');
  if btrim(coalesce(p_reason,''))='' then
    raise exception 'لا يُخرَج عضوٌ بلا سببٍ مكتوب';
  end if;
  update v2.committee_members
     set ended_on=current_date, end_reason=p_reason
   where committee_key=p_committee and school_id=p_school
     and person_id=p_person and ended_on is null;
  if not found then raise exception 'هذا المنسوب ليس جالسًا في اللجنة'; end if;
  return jsonb_build_object('ok',true);
end $function$
;
