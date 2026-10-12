-- public.v2_work_void(p_work uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9a0c99739e0bea41bf58a9810f3dde38
CREATE OR REPLACE FUNCTION public.v2_work_void(p_work uuid, p_reason text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare w record; v_me uuid := v2.current_person();
begin
  if coalesce(trim(p_reason),'') = '' then raise exception 'الإلغاءُ يلزمه سببٌ مكتوب'; end if;
  select * into w from v2.class_work where id = p_work;
  if w.id is null then raise exception 'عملٌ غيرُ موجود'; end if;
  if not v2.my_school(w.school_id) then raise exception 'ليست مدرستَك'; end if;
  if w.voided_at is not null then raise exception 'أُلغي من قبل'; end if;
  if w.by_person <> v_me then raise exception 'لا يُلغيه إلّا من كلّف به'; end if;
  if w.due_on < current_date and v2.rule_n(w.school_id,'work_void_after_due') <> 1 then
    raise exception 'مضى موعدُه — فصار تاريخًا يُقرأ ولا يُمحى';
  end if;

  update v2.class_work
     set voided_at = now(), voided_by = v_me, void_reason = trim(p_reason)
   where id = p_work;

  return jsonb_build_object('ok', true, 'msg', 'أُلغي العملُ — وبقي سببُه في السجلّ');
end $function$
;
