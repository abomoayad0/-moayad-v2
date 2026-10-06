-- public.v2_plan_save(p_school uuid, p_plan uuid, p_grade smallint, p_subject text, p_slots smallint, p_ord smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1dd47b52e7f7b66177bf57b84710e832
CREATE OR REPLACE FUNCTION public.v2_plan_save(p_school uuid, p_plan uuid, p_grade smallint, p_subject text, p_slots smallint, p_ord smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy'],'ضبطَ خطّة المواد');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_grade is null then raise exception 'اختر الصفّ'; end if;
  if btrim(coalesce(p_subject,''))='' then raise exception 'اكتب اسمَ المادّة'; end if;
  if p_slots is null or p_slots < 1 then raise exception 'اكتب عددَ حصص المادّة'; end if;

  if p_plan is null then
    insert into v2.subject_plan(school_id,grade,subject_ar,slots,ord)
    values (p_school,p_grade,btrim(p_subject),p_slots,coalesce(p_ord,0))
    on conflict (school_id,grade,subject_ar) do update set
      slots=excluded.slots, ord=excluded.ord, active=true
    returning id into nid;
    return jsonb_build_object('ok',true,'plan',nid);
  end if;
  update v2.subject_plan set grade=p_grade, subject_ar=btrim(p_subject),
    slots=p_slots, ord=coalesce(p_ord,ord)
   where id=p_plan and school_id=p_school;
  if not found then raise exception 'هذي الخطّةُ ليست لمدرستك'; end if;
  return jsonb_build_object('ok',true,'plan',p_plan);
end $function$
;
