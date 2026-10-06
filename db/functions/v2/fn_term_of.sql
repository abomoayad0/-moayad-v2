-- v2.fn_term_of(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 85705ef38a6c604c89637ba2a77dbfdf
CREATE OR REPLACE FUNCTION v2.fn_term_of(p_school uuid, p_date date)
 RETURNS smallint
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select coalesce(v2.term_of_strict(p_school,p_date), 1)::smallint;
$function$
;
