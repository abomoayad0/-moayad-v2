-- v2.log_action(p_school uuid, p_student uuid, p_action text, p_action_ar text, p_ref_table text, p_ref_id uuid, p_detail jsonb)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1ebc7026bf39d00cc8b2a8d2d0bdff66
CREATE OR REPLACE FUNCTION v2.log_action(p_school uuid, p_student uuid, p_action text, p_action_ar text, p_ref_table text, p_ref_id uuid, p_detail jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare me uuid;
begin
  me := v2.current_person();
  insert into v2.action_log(school_id,person_id,person_ar,role_ar,student_id,
      action,action_ar,ref_table,ref_id,detail,is_test)
  values (p_school, me,
      (select v2.fn_display_name(p.full_name) from v2.people p where p.id=me),
      coalesce(v2.role_ar(v2.my_role()),'—'),
      p_student, p_action, p_action_ar, p_ref_table, p_ref_id, p_detail,
      coalesce((select test_mode from v2.schools where id=p_school),false));
exception when others then null;   -- 🔑 القيدُ لا يُسقط الفعل
end $function$
;
