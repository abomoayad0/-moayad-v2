-- public.v2_skill_report_approve(p_report uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 83c9bf1bab77994d53992fdd21735756
CREATE OR REPLACE FUNCTION public.v2_skill_report_approve(p_report uuid, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; nm text;
begin
  perform v2.assert_role(array['deputy_academic','deputy','principal'],
    'اعتمادَ تقرير تقويم المهارات');
  select * into r from v2.skill_reports where id=p_report and voided_at is null;
  if r.id is null then raise exception 'لا تقريرَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(r.school_id,'اعتمادَ تقرير تقويم المهارات');
  if r.approved_at is not null then
    raise exception 'اعتُمد سلفًا في %', r.approved_at::date; end if;
  if r.weak and r.expert_at is null then
    raise exception 'الطالبُ ذو ضعفٍ أكاديميٍّ ولم تُسجَّل استشارةُ المعلّم الخبير — ونصُّه: %',
      v2.cite_of('assess.weak_with_expert'); end if;

  update v2.skill_reports
     set approved_by=v2.current_person(), approved_at=now(),
         approve_note=nullif(btrim(coalesce(p_note,'')),''), state='approved'
   where id=p_report;

  select v2.fn_display_name(full_name) into nm from v2.students where id=r.student_id;
  return jsonb_build_object('ok',true,'report',p_report,
    'summary_ar','اعتُمد تقريرُ '||coalesce(nm,'الطالب')||' — الدورةُ '||v2.ar_num(r.round_no),
    'note_ar','ويبقى إشعارُ وليّ الأمر — '||v2.cite_of('assess.guardian_twice'));
end $function$
;
