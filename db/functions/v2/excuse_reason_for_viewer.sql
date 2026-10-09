-- v2.excuse_reason_for_viewer(p_reason text, p_item smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 51dd7fcc50fd2ec8b35c08202aa99e05
CREATE OR REPLACE FUNCTION v2.excuse_reason_for_viewer(p_reason text, p_item smallint DEFAULT NULL::smallint)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r text;
begin
  r := v2.my_role();
  if r in ('principal','deputy','deputy_students','deputy_school','deputy_school_students',
           'deputy_academic','deputy_academic_school','admin_assistant',
           'admin_assistant_students','counselor','owner','admin') then
    return p_reason;
  end if;
  return 'غيابٌ بعذرٍ مقبول — والسببُ محفوظٌ عند إدارة المدرسة (م35)';
end $function$
;
