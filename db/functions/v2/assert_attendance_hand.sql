-- v2.assert_attendance_hand(p_what text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0b8a61868e419ce96d2b5c066dedfff5
CREATE OR REPLACE FUNCTION v2.assert_attendance_hand(p_what text)
 RETURNS void
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r text; c record;
begin
  -- 🔑 م35 بند 4: لا يُشرَك الموجّهُ الطلابيُّ في الحرمان ولا في حسم الدرجات
  r := v2.my_role();
  if r = 'counselor' then
    select * into c from v2.conduct_rules where key = 'attendance.counselor_excluded';
    raise exception 'الموجّهُ الطلابيُّ لا يُسجّل الغيابَ — فرصدُه يحسم درجةَ المواظبة. '
      'ونصُّ الدليل: «%» (م% · % %). والتسجيلُ لوكيل شؤون الطلبة أو المساعد الإداريّ أو المدير.',
      c.text_ar, c.article_no, c.source_doc, c.source_page;
  end if;
  perform v2.assert_role(array['principal','deputy','deputy_students',
      'admin_assistant','admin_assistant_students'], p_what);
end $function$
;
