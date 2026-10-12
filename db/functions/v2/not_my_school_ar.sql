-- v2.not_my_school_ar()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 717c0a6e0fb95478edf4e24cf22f2075
CREATE OR REPLACE FUNCTION v2.not_my_school_ar()
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare rk text; sc uuid; nm text;
begin
  select role_key, school_id into rk, sc from v2.session_role where user_id = auth.uid();
  if sc is not null then
    select name_ar into nm from v2.schools where id = sc;
    return format('أنت تعمل الآن بصفة «%s» في «%s» — ولا يقع هذا في مدرسةٍ أخرى. بدّل صفتك.',
                  coalesce(v2.role_ar(rk), rk, 'بلا تكليف'), coalesce(nm, '—'));
  end if;
  return 'هذه المدرسة ليست من مدارسك — فإن كان لك فيها تكليفٌ فاخترها في صفتك، وإلّا فلا يقع فيها عملُك.';
end $function$
;
