-- v2.task_form_no(p_kind text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e24a3fdf9103370d39183f9420c99fef
CREATE OR REPLACE FUNCTION v2.task_form_no(p_kind text)
 RETURNS smallint
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case p_kind
    when 'record_sign'      then 5    -- نموذج رصد مشكلة سلوكية
    when 'notify_guardian'  then 9    -- إشعار وليّ الأمر
    when 'summon_guardian'  then 10   -- خطاب دعوة وليّ الأمر
    when 'plan'             then 3    -- خطة تعديل السلوك
    when 'committee'        then 12   -- محضر لجنة التوجيه
    when 'counselor'        then 7    -- نموذج إحالة طالب
    when 'compensation'     then 6    -- فرص التعويض
    when 'pledge'           then 8    -- تعهّد سلوكي
    when 'incident'         then 11   -- محضر ضبط واقعة
  end::smallint;
$function$
;
