-- public.v2_remedial_build(p_school uuid, p_kind text, p_subject text, p_title text, p_skill uuid, p_student uuid, p_grade smallint, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1c7a3b5d0f3e07fc7963be4722f3a562
CREATE OR REPLACE FUNCTION public.v2_remedial_build(p_school uuid, p_kind text, p_subject text, p_title text, p_skill uuid, p_student uuid, p_grade smallint, p_term smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_id uuid; tm smallint; yr uuid; sk record; v_rep uuid; nm text;
begin
  perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher',
    'deputy_academic','deputy','principal'],'إعدادَ خطّةٍ علاجيّة');
  perform v2.assert_my_school(p_school,'إعدادَ خطّةٍ علاجيّة');
  if p_kind not in ('individual','group') then
    raise exception 'نوعُ الخطّة: فرديّةٌ (individual) أو جماعيّةٌ (group) — وكلتاهما منصوصةٌ في %',
      v2.cite_of('remedial.both_kinds'); end if;
  if btrim(coalesce(p_title,'')) = '' or btrim(coalesce(p_subject,'')) = '' then
    raise exception 'اكتب المادّةَ وعنوانَ الخطّة'; end if;

  tm := coalesce(p_term, v2.fn_term_of(p_school, current_date));
  select e.year_id into yr from v2.enrolments e where e.school_id=p_school and e.status='active' limit 1;

  select * into sk from v2.skills where id=p_skill and school_id=p_school and voided_at is null and active;
  if sk.id is null then
    raise exception 'التصنيفُ يكون على مهارةٍ من قائمة مدرستك — ونصُّه: %', v2.cite_of('remedial.build'); end if;

  if p_kind='individual' then
    if p_student is null then raise exception 'الخطّةُ الفرديّةُ تلزمها تسميةُ الطالب'; end if;
    perform v2.assert_my_student(p_student,'إعدادَ خطّةٍ علاجيّة');
    select sr.id into v_rep from v2.skill_reports sr
     where sr.school_id=p_school and sr.student_id=p_student and sr.term_no=tm and sr.voided_at is null
     order by sr.round_no desc limit 1;
  end if;

  insert into v2.remedial_plans(school_id,year_id,term_no,kind,subject_ar,grade,title_ar,
      class_by,skill_id,student_id,source_report,owner_person,is_test)
  values (p_school,yr,tm,p_kind,btrim(p_subject),coalesce(p_grade,sk.grade),btrim(p_title),
      'skill',p_skill,case when p_kind='individual' then p_student end, v_rep,
      v2.current_person(), coalesce((select test_mode from v2.schools where id=p_school),false))
  returning id into v_id;

  if p_kind='individual' then
    select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;
  end if;

  return jsonb_build_object('ok',true,'plan',v_id,'kind',p_kind,'term',tm,
    'skill_ar',sk.title_ar,'source_report',v_rep,
    'summary_ar','أُعدّت خطّةٌ '||case when p_kind='individual' then 'فرديّةٌ لـ'||coalesce(nm,'الطالب')
                                     else 'جماعيّةٌ' end
      ||' على مهارة «'||sk.title_ar||'» في '||btrim(p_subject),
    'note_ar', case when p_kind='group'
      then 'وأضِف طلّابَها ثمّ اقترح حصصَها · ثمّ تراجعها لجنةُ التوجيه الطلابيّ — '||v2.cite_of('remedial.group_review')
      else 'واقترح حصصَها ثمّ يعتمدها الوكيلُ للشؤون التعليميّة — '||v2.cite_of('remedial.approve') end
      ||case when v_rep is not null then ' · ومستندُها تقريرُ تقويم المهارات المُعدُّ لهذا الفصل' else '' end);
end $function$
;
