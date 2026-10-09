-- public.v2_pending_excuses(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f595503b38318e0ccf72745e9e9120d7
CREATE OR REPLACE FUNCTION public.v2_pending_excuses(p_school uuid)
 RETURNS TABLE(claim_id uuid, student_id uuid, student_name text, grade smallint, section text, class_ar text, from_date date, to_date date, from_h text, to_h text, days integer, submitted_on date, submitted_h text, by_whom text, channel text, reason_text text, attachment_name text, working_days_used smallint, window_verdict text, decision text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_school(p_school,'قراءة الأعذار المنتظرة');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant','admin_assistant_students','counselor'],
      'قراءةَ أسباب أعذار الغياب');
  return query select * from v2.fn_pending_excuses(p_school);
end $function$
;
