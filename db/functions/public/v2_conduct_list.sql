-- public.v2_conduct_list(p_student uuid, p_mode text, p_target text, p_stage text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 853b7e4174bfe587e8d91995dc6faae2
CREATE OR REPLACE FUNCTION public.v2_conduct_list(p_student uuid DEFAULT NULL::uuid, p_mode text DEFAULT 'onsite'::text, p_target text DEFAULT 'general'::text, p_stage text DEFAULT NULL::text)
 RETURNS TABLE(id integer, text_ar text, degree_no smallint, degree_ar text, stage_scope text, mode text, target text, source_page text, applies boolean, why text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc text;
begin
  if p_student is not null then
    perform v2.assert_my_student(p_student,'قراءة لائحة السلوك');
    select case when e.grade <= 6 then 'primary' else 'intermediate_secondary' end
      into sc from v2.enrolments e where e.student_id=p_student and e.status='active' limit 1;
  else
    sc := p_stage;
  end if;
  return query
   select p.id, p.text_ar, p.degree_no, 'الدرجة '||p.degree_no,
     p.stage_scope, p.mode, p.target, p.source_page,
     (sc is null or p.stage_scope = sc or p.stage_scope='all'),
     case when sc is null then null
          when p.stage_scope = sc or p.stage_scope='all' then null
          else 'لا تنطبق على مرحلة الطالب' end
   from v2.conduct_problems p
   where p.mode = p_mode and p.target = p_target
     and (sc is null or p.stage_scope = sc or p.stage_scope = 'all')
   order by p.degree_no, p.id;
end $function$
;
