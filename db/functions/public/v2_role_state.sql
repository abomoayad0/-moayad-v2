-- public.v2_role_state(p_school uuid, p_code text, p_on boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 185c6a808ff4e65dffd55e7334794a87
CREATE OR REPLACE FUNCTION public.v2_role_state(p_school uuid, p_code text, p_on boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students'],'إظهارَ دورٍ أو إخفاءه');
  perform v2.assert_my_school(p_school,'إظهارَ دورٍ أو إخفاءه');
  update v2.class_roles set active = coalesce(p_on,true)
   where code = p_code and (school_id = p_school or school_id is null);
  get diagnostics n = row_count;
  if n = 0 then raise exception 'دورٌ غيرُ موجود'; end if;
  return jsonb_build_object('ok',true,'msg', case when coalesce(p_on,true)
    then 'ظهر الدورُ للمعلّمين' else 'أُخفي الدورُ — ومن يحمله يبقى حتى يُعزل' end);
end $function$
;
