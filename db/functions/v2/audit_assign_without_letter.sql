-- v2.audit_assign_without_letter()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1646a4686918f9db1f9be7ab646aa21a
CREATE OR REPLACE FUNCTION v2.audit_assign_without_letter()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select 'تكليفٌ بلا خطاب · ' || v2.fn_display_name(p.full_name) || ' · ' ||
         coalesce((select po.label_ar from v2.posts po where po.key=a.post_key), a.post_key) ||
         ' · ' || s.name_ar,
         'التكليفُ نافذٌ ولم يُستكمل خطابُه — ' ||
         case when a.letter_no is null and a.letter_date is null then 'لا رقمَ ولا تاريخ'
              when a.letter_no is null then 'لا رقمَ له'
              else 'لا تاريخَ له' end ||
         ' · وقد بدأ ' || v2.fn_to_hijri(a.started_on) ||
         '. ويُعبّأ من لوحة التحكّم — والسندُ لا يُختلق.',
         'انتبه'
    from v2.assignments a
    join v2.people p on p.id = a.person_id
    join v2.schools s on s.id = a.school_id
   where a.ended_on is null and (a.letter_no is null or a.letter_date is null);
$function$
;
