-- public.v2_census_of(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6e857d0432c96c64262c58ca79059913
CREATE OR REPLACE FUNCTION public.v2_census_of(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_student(p_student,'حصر السلوكيات');
  select coalesce(jsonb_agg(jsonb_build_object(
      'census',c.id,'state',c.state,'by_self',c.by_self,
      'who', case when c.by_self then 'حصرُك'
             else 'حصرُ المكلَّف ('||coalesce(
               (select v2.fn_display_name(p.full_name) from v2.people p where p.id=c.assigned_to),
               '—')||')' end,
      'assigned_at',c.assigned_at::date,'due',c.due_on,
      'late',(c.state='مكلَّف' and c.due_on < current_date),
      'by',(select v2.fn_display_name(p.full_name) from v2.people p where p.id=c.assigned_by),
      'neg',(select coalesce(jsonb_agg(jsonb_build_object('icon',x.icon,'text',x.text_ar)
              order by x.ord),'[]'::jsonb) from v2.census_items x
              where x.id = any(coalesce(c.neg_items,'{}'::uuid[]))),
      'pos',(select coalesce(jsonb_agg(jsonb_build_object('icon',x.icon,'text',x.text_ar)
              order by x.ord),'[]'::jsonb) from v2.census_items x
              where x.id = any(coalesce(c.pos_items,'{}'::uuid[]))),
      'neg_n',coalesce(array_length(c.neg_items,1),0),
      'pos_n',coalesce(array_length(c.pos_items,1),0),
      'summary', case when c.neg_items is null then null
        else v2.ar_num(coalesce(array_length(c.neg_items,1),0))||' سلبيّةً · '||
             v2.ar_num(coalesce(array_length(c.pos_items,1),0))||' إيجابيّة' end,
      'causes',c.causes,'suggestion',c.suggestion,
      'filed_at',c.filed_at,'returned_why',c.returned_why)
      order by c.assigned_at desc),'[]'::jsonb)
  into r from v2.behavior_census c where c.student_id=p_student;
  return r;
end $function$
;
