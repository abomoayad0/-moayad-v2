-- public.v2_swap_matches(p_my_slot uuid, p_on date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e8f3439163d5c34ac2e31ebbad622c0e
CREATE OR REPLACE FUNCTION public.v2_swap_matches(p_my_slot uuid, p_on date DEFAULT CURRENT_DATE)
 RETURNS TABLE("الحصّة" smallint, "الفصل" text, "المادة" text, "المعلّم" text, "الحال" text, "يستطيع" boolean, slot_id uuid, person_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select m.period_no, m.section_ar, coalesce(m.subject_ar,'—'), m.person_ar,
         m.why_ar, m.ok, m.slot, m.person_id
  from v2.swap_matches(p_my_slot, p_on) m
  where exists (select 1 from v2.timetable t
                 where t.id = p_my_slot and t.person_id = v2.current_person())
$function$
;
