-- public.v2_problems(p_school uuid, p_degree smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 680b5d2e13e959de4dda30f6688f1014
CREATE OR REPLACE FUNCTION public.v2_problems(p_school uuid, p_degree smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r jsonb; st text; md text;
begin
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select stage into st from v2.schools where id=p_school;
  md := v2.conduct_mode_of(p_school);
  if md is null then
    raise exception 'لم يُضبط نمطُ التعليم لمدرستك — اضبطه من لوحة التحكّم: «إعداداتُ السلوك للمدرسة»';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'id',cp.id,'text',cp.text_ar,
      'degree',cp.degree_no,'degree_ar',v2.degree_ar(cp.degree_no),
      'page_ar', translate(coalesce(cp.source_page,''),'0123456789','٠١٢٣٤٥٦٧٨٩'),
      'once_per_day',cp.once_per_day,'repeat_key',cp.repeat_key,
      'advice_n',(select count(*) from v2.conduct_advice a
                   where a.problem_id=cp.id and a.active
                     and (a.school_id is null or a.school_id=p_school)),
      'bank_n',(select count(*) from v2.phrase_bank b
                 where b.problem_id=cp.id and b.active
                   and (b.school_id is null or b.school_id=p_school)))
      order by cp.degree_no, cp.item_no),'[]'::jsonb)
  into r from v2.conduct_problems cp
  where cp.mode = md
    and (p_degree is null or cp.degree_no=p_degree)
    and (cp.stage_scope='all'
      or (st='primary' and cp.stage_scope='primary')
      or (st<>'primary' and cp.stage_scope='intermediate_secondary'));
  return jsonb_build_object(
    'mode', md, 'mode_ar', v2.conduct_mode_ar(md),
    'note_ar', 'المدرسةُ تعمل بـ'||v2.conduct_mode_ar(md)||' — والسلّمُ الآخرُ محفوظٌ ويُفتح من لوحة التحكّم',
    'items', r);
end
$function$
;
