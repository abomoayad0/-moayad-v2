-- public.v2_skills_list(p_school uuid, p_subject text, p_grade smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b08f9dd90a1a87f180064e48967253bf
CREATE OR REPLACE FUNCTION public.v2_skills_list(p_school uuid, p_subject text DEFAULT NULL::text, p_grade smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_school(p_school,'قراءةَ قائمة المهارات');
  select coalesce(jsonb_agg(jsonb_build_object(
      'skill', s.id, 'subject_ar', s.subject_ar,
      'grade', s.grade, 'code', s.code, 'title_ar', s.title_ar,
      'kind', s.kind,
      'kind_ar', case s.kind when 'minimum' then 'حدٌّ أدنى' else 'مستهدفة' end,
      'ord', s.ord, 'source_ar', coalesce(s.source_ar,'—'),
      'marks_n', (select count(*) from v2.skill_marks m where m.skill_id=s.id and m.voided_at is null)
    ) order by s.subject_ar, s.grade nulls first, s.ord, s.title_ar), '[]'::jsonb) into r
    from v2.skills s
   where s.school_id=p_school and s.voided_at is null and s.active
     and (p_subject is null or s.subject_ar = p_subject)
     and (p_grade is null or s.grade is null or s.grade = p_grade);

  return jsonb_build_object('ok',true,'rows',r,'count',jsonb_array_length(r),
    'summary_ar', case when jsonb_array_length(r)=0
      then 'قائمةُ المهارات فارغةٌ — وهي مدخلٌ تُدخله المدرسةُ، ولا تُخترع فيها مهارةٌ بلا سند'
      else v2.ar_count(jsonb_array_length(r),'مهارةٌ واحدة','مهارتان','مهاراتٍ','مهارةً') end,
    'basis_ar',v2.cite_of('assess.inputs'));
end $function$
;
