-- public.v2_plan_lock(p_plan uuid, p_why text, p_open boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 65c0a4e54711c3440309b1cdb1a7226f
CREATE OR REPLACE FUNCTION public.v2_plan_lock(p_plan uuid, p_why text, p_open boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_sub text; v_gr smallint;
begin
  select school_id, subject_ar, grade into v_school, v_sub, v_gr
    from v2.lesson_plans where id=p_plan;
  if v_school is null then raise exception 'لا خطّةَ بهذا الرقم'; end if;
  perform v2.assert_my_school(v_school,'إقفالَ التوزيع');
  perform v2.assert_role(array['deputy_academic','deputy','deputy_school','principal'],
    'إقفالَ التوزيع');
  if btrim(coalesce(p_why,'')) = '' then
    raise exception 'سببُ الإقفال أو الفتح مطلوب';
  end if;

  update v2.lesson_plans
     set is_locked = not coalesce(p_open,false),
         locked_by = v2.current_person(), locked_at = now(), lock_why = btrim(p_why)
   where id = p_plan;

  return jsonb_build_object('ok',true,'is_locked', not coalesce(p_open,false),
    'summary_ar', case when coalesce(p_open,false)
      then 'فُتح تعديلُ توزيع «'||v_sub||'» للصفّ '||v_gr
      else 'أُقفل تعديلُ توزيع «'||v_sub||'» للصفّ '||v_gr||' — والرصدُ يبقى مفتوحًا' end);
end $function$
;
