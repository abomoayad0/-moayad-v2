-- public.v2_swap_options(p_school uuid, p_on date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5469b9c561e37dc06e6ac652ebeb4fca
CREATE OR REPLACE FUNCTION public.v2_swap_options(p_school uuid, p_on date DEFAULT CURRENT_DATE)
 RETURNS TABLE("الحصّة" smallint, "الفصل" text, "المادة" text, "حالُها" text, slot_id uuid)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select e.period_no,
    coalesce((select cs.label_ar from v2.class_sections cs where cs.id=e.section_id),'—'),
    coalesce(e.subject_ar,'—'),
    case when exists (select 1 from v2.period_swaps w
                       where w.school_id=p_school and w.on_date=p_on and w.req_slot=e.slot
                         and w.status in ('pending','partner_ok','done'))
              then 'مطلوبٌ تبديلُها' else 'متاحة' end,
    e.slot
  from v2.effective_periods(p_school, v2.current_person(), p_on) e
  where v2.my_school(p_school) and e.basis = 'schedule'
  order by e.period_no
$function$
;
