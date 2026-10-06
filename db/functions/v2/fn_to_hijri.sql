-- v2.fn_to_hijri(p date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1d1e36634db3f570adba24be16e6e1c4
CREATE OR REPLACE FUNCTION v2.fn_to_hijri(p date)
 RETURNS text
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
  select m.h_year||'/'||m.h_month||'/'||(p - m.starts_g + 1)
  from v2.hijri_months m
  where p >= m.starts_g and p < m.starts_g + m.days_count
  limit 1;
$function$
;
