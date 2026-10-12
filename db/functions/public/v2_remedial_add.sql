-- public.v2_remedial_add(p_plan uuid, p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 124516aea10ed34d2d5c278de5b35fd1
CREATE OR REPLACE FUNCTION public.v2_remedial_add(p_plan uuid, p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare p record; v_max int; n int; nm text;
begin
  select * into p from v2.remedial_plans where id=p_plan and voided_at is null;
  if p.id is null then raise exception 'لا خطّةَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(p.school_id,'إضافةَ طالبٍ إلى خطّةٍ علاجيّة');
  perform v2.assert_my_student(p_student,'إضافةَ طالبٍ إلى خطّةٍ علاجيّة');
  if p.kind <> 'group' then raise exception 'الخطّةُ فرديّةٌ — ولا تُضاف إليها مجموعة'; end if;
  if p.state in ('approved','running','evaluated') then
    raise exception 'الخطّةُ اعتُمدت — ولا يُغيَّر أعضاؤها بعد الاعتماد'; end if;

  v_max := v2.rule_n(p.school_id,'remedial_group_max');
  select count(*) into n from v2.remedial_members m where m.plan_id=p_plan and m.removed_at is null;
  if n >= v_max then
    raise exception 'بلغت المجموعةُ سقفَها — وأكثرُها % طلّاب (رقمٌ في لوحة التحكّم)', v2.ar_num(v_max); end if;

  insert into v2.remedial_members(plan_id,student_id,added_by,is_test)
  values (p_plan,p_student,v2.current_person(),coalesce(p.is_test,false))
  on conflict (plan_id,student_id) where removed_at is null do nothing;

  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;
  select count(*) into n from v2.remedial_members m where m.plan_id=p_plan and m.removed_at is null;
  return jsonb_build_object('ok',true,'plan',p_plan,'members',n,'max',v_max,
    'summary_ar','أُضيف '||coalesce(nm,'الطالب')||' — وصار في المجموعة '||v2.ar_num(n)||' من '||v2.ar_num(v_max));
end $function$
;
