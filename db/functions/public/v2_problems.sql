-- public.v2_problems(p_school uuid, p_degree smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7376cb3ccb03e693004726f30716c65f
CREATE OR REPLACE FUNCTION public.v2_problems(p_school uuid, p_degree smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; st text;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select stage into st from v2.schools where id=p_school;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',cp.id,'text',cp.text_ar,
      'degree',cp.degree_no,'degree_ar',v2.degree_ar(cp.degree_no),
      'page_ar',cp.source_page,
      'once_per_day',cp.once_per_day,'repeat_key',cp.repeat_key,
      'advice_n',(select count(*) from v2.conduct_advice a
                   where a.problem_id=cp.id and a.active
                     and (a.school_id is null or a.school_id=p_school)),
      'bank_n',(select count(*) from v2.phrase_bank b
                 where b.problem_id=cp.id and b.active
                   and (b.school_id is null or b.school_id=p_school)))
      order by cp.degree_no, cp.item_no),'[]'::jsonb)
  into r from v2.conduct_problems cp
  where cp.mode='onsite'
    and (p_degree is null or cp.degree_no=p_degree)
    and (cp.stage_scope='all'
      or (st='primary' and cp.stage_scope='primary')
      or (st<>'primary' and cp.stage_scope='intermediate_secondary'));
  return r;
end $function$
;
