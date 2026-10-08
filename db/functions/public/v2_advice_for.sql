-- public.v2_advice_for(p_problem integer, p_occurrence smallint, p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9bc6d57c864b2775f54fc79ec21a9a82
CREATE OR REPLACE FUNCTION public.v2_advice_for(p_problem integer, p_occurrence smallint, p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t text; n smallint;
begin
  if auth.uid() is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  select max(occurrence) into n from v2.conduct_advice
   where problem_id=p_problem and active
     and (school_id is null or school_id=p_school);
  if n is null then return jsonb_build_object('text',null); end if;
  select text_ar into t from v2.conduct_advice a
   where a.problem_id=p_problem and a.active
     and (a.school_id is null or a.school_id=p_school)
     and a.occurrence = least(coalesce(p_occurrence,1), n)
   order by (a.school_id is null) limit 1;
  return jsonb_build_object('text',t,'occurrence',least(coalesce(p_occurrence,1),n));
end $function$
;
