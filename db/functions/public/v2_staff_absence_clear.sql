-- public.v2_staff_absence_clear(p_school uuid, p_person uuid, p_date date, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 274ae537ac68a76da119bfc807458cef
CREATE OR REPLACE FUNCTION public.v2_staff_absence_clear(p_school uuid, p_person uuid, p_date date DEFAULT CURRENT_DATE, p_why text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n int;
begin
  perform v2.assert_role(array['admin_assistant','deputy_school','principal'],
                         'رفع غياب منسوب');
  perform v2.assert_my_school(p_school, 'رفع غياب منسوب');
  update v2.staff_absences set voided_at = now(), voided_by = v2.current_person(),
         void_why = coalesce(nullif(btrim(p_why),''),'رُفع الغياب')
   where school_id = p_school and person_id = p_person and on_date = p_date and voided_at is null;
  if not found then raise exception 'لا غيابَ مسجَّلٌ له في هذا اليوم'; end if;

  with g as (
    update v2.period_covers set voided_at = now(), voided_by = v2.current_person(),
           void_why = 'رُفع غيابُ صاحب الحصّة'
     where school_id = p_school and on_date = p_date and absent_person = p_person
       and voided_at is null and decided = 'auto'
    returning 1)
  select count(*) into n from g;
  return 'رُفع الغياب' ||
    case when n > 0 then ' · وسُحبت ' || v2.ar_count(n,'تغطيةٌ آليّة','تغطيتان آليّتان','تغطياتٍ آليّة','تغطيةً آليّة')
         else '' end;
end $function$
;
