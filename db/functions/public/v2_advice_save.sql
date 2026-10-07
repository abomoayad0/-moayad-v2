-- public.v2_advice_save(p_school uuid, p_problem integer, p_occurrence smallint, p_text text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9e739392933ece3f0083d975ecd821d3
CREATE OR REPLACE FUNCTION public.v2_advice_save(p_school uuid, p_problem integer, p_occurrence smallint, p_text text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','counselor'],
                         'ضبطَ النصائح التربويّة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_occurrence is null or p_occurrence < 1 then raise exception 'رقمُ الرصدة من واحدٍ فأكثر'; end if;
  if btrim(coalesce(p_text,''))='' then raise exception 'اكتب النصيحة'; end if;
  insert into v2.conduct_advice(school_id,problem_id,occurrence,text_ar)
  values (p_school,p_problem,p_occurrence,btrim(p_text))
  on conflict (school_id,problem_id,occurrence) do update set text_ar=excluded.text_ar, active=true;
  return jsonb_build_object('ok',true);
end $function$
;
