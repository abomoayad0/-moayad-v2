-- public.v2_pending_excuses(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 77a8248b4e2f0052619bdb7230e78eb7
CREATE OR REPLACE FUNCTION public.v2_pending_excuses(p_school uuid)
 RETURNS TABLE(claim_id uuid, student_id uuid, student_name text, grade smallint, section text, class_ar text, from_date date, to_date date, from_h text, to_h text, days integer, submitted_on date, submitted_h text, by_whom text, channel text, reason_text text, attachment_name text, working_days_used smallint, window_verdict text, decision text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة الأعذار المنتظرة');
  return query select * from v2.fn_pending_excuses(p_school);
end $function$
;
