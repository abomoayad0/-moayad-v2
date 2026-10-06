-- public.v2_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_by text, p_channel text, p_excuse_item smallint, p_attachment_name text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6191966f464b3e23c483eafce5d49386
CREATE OR REPLACE FUNCTION public.v2_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_by text DEFAULT 'guardian'::text, p_channel text DEFAULT 'in_person'::text, p_excuse_item smallint DEFAULT NULL::smallint, p_attachment_name text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_student(p_student,'تقديم عذر');
  return v2.fn_submit_excuse(p_student,p_from,p_to,p_by,p_channel,p_excuse_item,p_reason,null,p_attachment_name,current_date);
end $function$
;
