-- public.v2_plan_of(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 37bd948fc342f50c1c5541cef4043c92
CREATE OR REPLACE FUNCTION public.v2_plan_of(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_student_or_kin(p_student,'خطة تعديل السلوك');
  select coalesce(jsonb_agg(jsonb_build_object(
      'plan',p.id,'status',p.status,
      'state_ar', case p.status when 'draft' then 'مسودّة' when 'active' then 'سارية'
                    when 'final' then 'معتمدة' when 'closed' then 'مغلقة' else p.status end,
      'desc',p.problem_desc,'manifest',p.manifestations,
      'ante',p.antecedents,'conseq',p.consequences,'gain',p.student_gain,
      'prior',p.prior_actions,'target',p.target_behavior,'steps',array_to_string(p.steps,E'\n'),'steps_list',to_jsonb(p.steps),
      'starts',p.starts_on,'ends',p.ends_on,
      'deputy',p.deputy_opinion,'teacher',p.teacher_opinion,'guardian',p.guardian_opinion,
      'teacher_at',p.teacher_at,'guardian_at',p.guardian_at,
      'needs_teacher',(p.teacher_opinion is null),
      'needs_guardian',(p.guardian_opinion is null),
      'can_final',(p.status='draft' and p.teacher_opinion is not null),
      'final_at',p.final_at,
      'final_by',(select v2.fn_display_name(x.full_name) from v2.people x where x.id=p.final_by),
      'by',(select v2.fn_display_name(x.full_name) from v2.people x where x.id=p.owner_person))
      order by p.created_at desc),'[]'::jsonb)
  into r from v2.behavior_plans p where p.student_id=p_student;
  return r;
end $function$
;
