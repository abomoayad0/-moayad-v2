-- public.v2_plan_prepared(p_plan uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 205ef3fd60900e9a62074f7cbc731f6b
CREATE OR REPLACE FUNCTION public.v2_plan_prepared(p_plan uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record; v_unplaced int;
begin
  select * into g from v2.plan_guard(p_plan,'إعلانَ إعداد التوزيع');
  select count(*) into v_unplaced from v2.lesson_plan_items
   where plan_id=p_plan and week_no is null;
  if v_unplaced > 0 then
    raise exception '% بندًا بلا أسبوعٍ — ولا يُعلَن الإعدادُ وفي الخطّة بنودٌ معلَّقة. فانقلها أو أعِد الحساب',
      v_unplaced;
  end if;
  update v2.lesson_plans
     set status='prepared', prepared_by=v2.current_person(), prepared_at=now()
   where id=p_plan;
  return jsonb_build_object('ok',true,'status','prepared',
    'summary_ar','أُعلن إعدادُ التوزيع — وينتظر المراجعةَ ثمّ اعتمادَ الوكيل للشؤون التعليميّة');
end $function$
;
