-- public.v2_decide_excuse(p_claim uuid, p_accept boolean, p_note text, p_principal_ext boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e261da2d53e393e9c0e07e820eb436ca
CREATE OR REPLACE FUNCTION public.v2_decide_excuse(p_claim uuid, p_accept boolean, p_note text DEFAULT NULL::text, p_principal_ext boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare st uuid; r jsonb;
begin
  select student_id into st from v2.absence_excuse_claims where id=p_claim;
  if st is null then raise exception 'العذر غير موجود'; end if;
  perform v2.assert_my_student(st,'البتّ في العذر');
  perform v2.assert_role(array['deputy_students','deputy'],'البتّ في الأعذار');
  if not p_accept and btrim(coalesce(p_note,''))='' then
    raise exception 'ردّ العذر لا يقع بلا سبب مكتوب'; end if;
  select to_jsonb(z) into r from v2.fn_decide_excuse(p_claim,p_accept,v2.current_person(),p_note,p_principal_ext) z;
  return r;
end $function$
;
