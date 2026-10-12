-- public.v2_plan_review(p_plan uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bd0a8faaadfd23a790abb2f4790a7fd1
CREATE OR REPLACE FUNCTION public.v2_plan_review(p_plan uuid, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record; v_me uuid := v2.current_person(); v_rank text;
        v_status text; v_assignee uuid; v_path text; v_best text; v_have text;
begin
  select * into g from v2.plan_guard(p_plan,'مراجعةَ التوزيع');
  select status, review_assignee into v_status, v_assignee from v2.lesson_plans where id=p_plan;

  if v_status = 'draft' then
    raise exception 'لم يُعلن المعلّمُ إعدادَ التوزيع بعد — ولا يُراجع ما لم يُعدَّ';
  end if;
  if v_status in ('reviewed','approved') then
    raise exception 'هذا التوزيعُ رُوجع من قبل';
  end if;
  if v_me = g.owner_person then
    raise exception 'لا يُراجع المعلّمُ توزيعَ نفسه — فالمراجعةُ عينٌ ثانية';
  end if;

  select pe.rank_key into v_rank from v2.people pe where pe.id = v_me;
  select min(case r.rank_key when 'expert' then 1 else 2 end)::text into v_best
    from v2.plan_reviewers(g.school_id, g.subject_ar) r;
  select string_agg(coalesce(r.full_name,'—')||' ('||coalesce(r.rank_ar,r.rank_key)||')',' · ')
    into v_have from v2.plan_reviewers(g.school_id, g.subject_ar) r;

  if v_best = '1' then
    if v_rank <> 'expert' then
      raise exception 'مراجعةُ خطّة الدروس للمعلّم الخبير — وفي مدرستك: %', v_have; end if;
    v_path := 'expert';
  elsif v_best = '2' then
    if v_rank not in ('expert','advanced') then
      raise exception 'مراجعةُ خطّة الدروس للمعلّم المتقدّم عند خلوّ الخبير — وفي مدرستك: %', v_have; end if;
    v_path := 'advanced';
  else
    if v_assignee is null then
      raise exception 'لا خبيرَ ولا متقدّمَ في المادّة — ولم يُكلّف المديرُ مراجعًا بعد. فاطلب تكليفَه.'; end if;
    if v_assignee <> v_me then
      raise exception 'المراجعةُ مكلَّفٌ بها غيرُك بأمر المدير'; end if;
    v_path := 'assigned_by_principal';
  end if;

  update v2.lesson_plans
     set status='reviewed', reviewed_by=v_me, reviewed_at=now(),
         review_path=v_path, review_note=nullif(btrim(coalesce(p_note,'')),'')
   where id=p_plan;

  return jsonb_build_object('ok',true,'status','reviewed','review_path',v_path,
    'summary_ar','رُوجع توزيعُ «'||g.subject_ar||'» للصفّ '||g.grade
      ||' — وينتظر اعتمادَ الوكيل للشؤون التعليميّة',
    'note_ar', case v_path
      when 'expert' then 'بالمعلّم الخبير — وهو الأصلُ في الدليل'
      when 'advanced' then 'بالمعلّم المتقدّم لخلوّ الخبير — ونصُّه في الدليل ص٩٩'
      else 'بمراجعٍ كلَّفه المديرُ لخلوّ الخبير والمتقدّم' end);
end $function$
;
