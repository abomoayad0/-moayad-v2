-- public.v2_advice_for(p_problem integer, p_occurrence smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 c57275aa2f48495afba5a0e4d425fd0e
CREATE OR REPLACE FUNCTION public.v2_advice_for(p_problem integer, p_occurrence smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t text; n smallint;
begin
  if auth.uid() is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  select max(occurrence) into n from v2.conduct_advice
   where problem_id=p_problem and active;
  if n is null then return jsonb_build_object('text',null); end if;
  select text_ar into t from v2.conduct_advice
   where problem_id=p_problem and active
     and occurrence = least(coalesce(p_occurrence,1), n) limit 1;
  return jsonb_build_object('text',t,'occurrence',least(coalesce(p_occurrence,1),n));
end $function$
;
