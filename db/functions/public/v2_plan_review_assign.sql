-- public.v2_plan_review_assign(p_plan uuid, p_person uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 720763f8fb76aeb05ba6d2b89c559762
CREATE OR REPLACE FUNCTION public.v2_plan_review_assign(p_plan uuid, p_person uuid, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record; v_have text; v_name text;
begin
  select * into g from v2.plan_guard(p_plan,'تكليفَ مراجعٍ للتوزيع');
  perform v2.assert_role(array['principal'],'تكليفَ مراجعٍ للتوزيع');
  if btrim(coalesce(p_why,'')) = '' then
    raise exception 'سببُ التكليف مطلوبٌ — ولا يُكلَّف مراجعٌ بلا سبب';
  end if;

  select string_agg(coalesce(r.full_name,'—')||' ('||coalesce(r.rank_ar,r.rank_key)||')', ' · ')
    into v_have from v2.plan_reviewers(g.school_id, g.subject_ar) r;
  if v_have is not null then
    raise exception 'لا يُكلَّف مراجعٌ وفي مدرستك من يصلح لها نظامًا: %. فالمراجعةُ له.', v_have;
  end if;

  select pe.full_name into v_name from v2.people pe
    join v2.assignments a on a.person_id=pe.id and a.school_id=g.school_id and a.ended_on is null
   where pe.id = p_person;
  if v_name is null then
    raise exception 'هذا المنسوبُ ليس من مدرستك — ولا يُكلَّف بمراجعة توزيعها';
  end if;
  if p_person = g.owner_person then
    raise exception 'لا يُراجع المعلّمُ توزيعَ نفسه — فكلِّف غيرَه';
  end if;

  update v2.lesson_plans
     set review_assignee = p_person, assigned_by = v2.current_person(),
         assigned_at = now(), assign_why = btrim(p_why)
   where id = p_plan;

  return jsonb_build_object('ok',true,'reviewer',p_person,
    'summary_ar','كُلِّف «'||v_name||'» بمراجعة توزيع «'||g.subject_ar||'» للصفّ '||g.grade,
    'note_ar','ولا خبيرَ ولا متقدّمَ في المادّة بمدرستك — فالتكليفُ بأمر المدير، ومُسجَّلٌ بسببه.');
end $function$
;
