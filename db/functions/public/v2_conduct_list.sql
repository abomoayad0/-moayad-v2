-- public.v2_conduct_list(p_student uuid, p_mode text, p_target text, p_stage text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6999483e03203fe504fe3d277d6aae19
CREATE OR REPLACE FUNCTION public.v2_conduct_list(p_student uuid, p_mode text DEFAULT NULL::text, p_target text DEFAULT NULL::text, p_stage text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare st text; r jsonb; sc text; md text; sch uuid;
begin
  perform v2.assert_my_student(p_student,'قائمة المخالفات');
  select coalesce(p_stage, e.stage), e.school_id into st, sch from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if st is null then raise exception 'الطالب لا قيد فعال له في سنة دراسية'; end if;
  sc := case when st='primary' then 'primary' else 'intermediate_secondary' end;

  md := v2.conduct_mode_of(sch);
  if md is null then
    raise exception 'لم يُضبط نمطُ التعليم لمدرستك — اضبطه من لوحة التحكّم: «إعداداتُ السلوك للمدرسة»';
  end if;
  if p_mode is not null and p_mode <> md then
    raise exception 'مدرستُك تعمل بـ% — وسلّمُ % محفوظٌ كاملًا ويُفتح بتغيير نمط التعليم من لوحة التحكّم',
      v2.conduct_mode_ar(md), v2.conduct_mode_ar(p_mode);
  end if;

  select coalesce(jsonb_agg(jsonb_build_object(
      'id',p.id,
      'text', rtrim(btrim(p.text_ar),'.'),
      'degree',p.degree_no,
      'degree_ar', v2.degree_ar(p.degree_no),
      'item_no',p.item_no,'target',p.target,
      'page_ar', v2.page_ar(p.source_page),
      'source', p.source_doc||' '||p.source_page,
      'once_per_day', p.once_per_day,
      'repeat_key',   p.repeat_key,
      'needs_period', (p.repeat_key = 'period'),
      'steps', (select max(a.step_no) from v2.conduct_actions a
                 where a.degree_no=p.degree_no and a.stage_scope=p.stage_scope
                   and a.mode=p.mode and a.target=p.target),
      'done', (select count(*) from v2.behavior_records br
                where br.student_id=p_student and br.problem_id=p.id and br.status<>'voided'),
      'today', exists (select 1 from v2.behavior_records br
                where br.student_id=p_student and br.problem_id=p.id
                  and br.status<>'voided' and br.created_at::date=current_date))
      order by p.degree_no, p.item_no),'[]'::jsonb)
  into r from v2.conduct_problems p
  where p.mode = md
    and p.stage_scope in (sc,'all')
    and (p_target is null or p.target = p_target);
  return r;
end
$function$
;
