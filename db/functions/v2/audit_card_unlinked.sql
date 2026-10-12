-- v2.audit_card_unlinked()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 756a9e16b48a008e020f93eac7a51966
CREATE OR REPLACE FUNCTION v2.audit_card_unlinked()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select s.name_ar||' — '||v2.ar_num(count(*))||' حدثًا',
         'أحداثٌ في بطاقة الطالب لم تُرفع إلى المحرّك الرسميّ · وأقدمُها قبل '
           ||v2.ar_num((current_date - min(ce.on_date))::int)||' يومًا · والحدُّ '
           ||v2.ar_num(v2.rule_n(ce.school_id,'card_link_days'))||' أيّام (رقمٌ في لوحة التحكّم)',
         'خلل'
    from v2.card_events ce join v2.schools s on s.id=ce.school_id
   where ce.linked_at is null and ce.undone_at is null
     and ce.on_date < current_date - v2.rule_n(ce.school_id,'card_link_days')
   group by s.name_ar, ce.school_id
$function$
;
