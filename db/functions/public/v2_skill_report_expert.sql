-- public.v2_skill_report_expert(p_report uuid, p_expert uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 94343fad478f8f4dfc77681979b67860
CREATE OR REPLACE FUNCTION public.v2_skill_report_expert(p_report uuid, p_expert uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; v_min int; nm text;
begin
  select * into r from v2.skill_reports where id=p_report and voided_at is null;
  if r.id is null then raise exception 'لا تقريرَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(r.school_id,'تسجيلَ استشارة المعلّم الخبير');
  perform v2.assert_role(array['subject_teacher','deputy_academic','deputy','principal'],
    'تسجيلَ استشارة المعلّم الخبير');
  if r.state in ('approved','notified') then
    raise exception 'التقريرُ اعتُمد سلفًا — ولا تُضاف استشارةٌ بعد الاعتماد'; end if;
  if not exists (select 1 from v2.assignments a
                  where a.person_id=p_expert and a.school_id=r.school_id and a.ended_on is null) then
    raise exception 'المعلّمُ الخبيرُ ليس من منسوبي مدرستك'; end if;
  v_min := v2.rule_n(r.school_id,'reason_min_chars');
  if length(btrim(coalesce(p_note,''))) < v_min then
    raise exception 'رأيُ المعلّم الخبير لا يُسجَّل بلا نصٍّ — وأقلُّه % حرفًا', v2.ar_num(v_min); end if;

  update v2.skill_reports
     set expert_person=p_expert, expert_at=now(), expert_note_ar=btrim(p_note)
   where id=p_report;

  select v2.fn_display_name(full_name) into nm from v2.people where id=p_expert;
  return jsonb_build_object('ok',true,'report',p_report,'expert',nm,
    'summary_ar','سُجّل رأيُ المعلّم الخبير '||coalesce(nm,'—'),
    'note_ar','وتحديدُ ذوي الضعف الأكاديميّ يكون باستشارته — '||v2.cite_of('assess.weak_with_expert')
      ||' · 🟠 ولا صفةَ «معلّم خبير» في النظام بعد، فالاستشارةُ مسجَّلةٌ باسم شخصٍ لا بصفة.');
end $function$
;
