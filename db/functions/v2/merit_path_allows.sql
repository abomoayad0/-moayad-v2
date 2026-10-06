-- v2.merit_path_allows(p_path text, p_write boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b63c5e11960bdb9818b48042280526b0
CREATE OR REPLACE FUNCTION v2.merit_path_allows(p_path text, p_write boolean)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare x record; who text;
begin
  if p_path is null or p_path not like 'merit/%' then return false; end if;

  select e.id, e.student_id, o.school_id into x
    from v2.merit_entries e join v2.merit_opportunities o on o.id = e.opp_id
   where p_path like 'merit/'||o.school_id||'/'||e.student_id||'/'||e.id||'/%'
   limit 1;
  if x.id is null then return false; end if;

  who := v2.caller_kind(x.student_id);
  if who in ('student','guardian') then return true; end if;

  if not v2.my_school(x.school_id) then return false; end if;
  if p_write then
    -- ص١٦ بند ٦: الشواهدُ تُقدَّم لوكيل شؤون الطلبة — فله الرفعُ نيابةً
    return v2.my_role() in ('deputy_students','deputy','principal');
  end if;
  -- والقراءةُ لمنسوبي المدرسة: المقرُّ واللجنةُ والوكيل
  return true;
end $function$
;
