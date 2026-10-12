-- public.v2_plan_build(p_school uuid, p_grade smallint, p_subject text, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 51fe70b81b5c564d4e814c7b8a222583
CREATE OR REPLACE FUNCTION public.v2_plan_build(p_school uuid, p_grade smallint, p_subject text, p_term smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_teacher boolean := false;
begin
  begin
    perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
      'admin_assistant','info_registrar'],'حسابَ توزيع المنهج');
  exception when others then v_teacher := true; end;
  if not v_teacher then
    raise exception 'سمِّ المعلّم — فالتوزيعُ للمعلّم في مادّته وصفّه، ولا يُحسب توزيعٌ بلا صاحب';
  end if;
  return public.v2_plan_build(p_school, p_grade, p_subject, p_term, v2.current_person());
end $function$
;
