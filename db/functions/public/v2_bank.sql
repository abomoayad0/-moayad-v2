-- public.v2_bank(p_key text, p_problem integer, p_school uuid, p_all boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 55c424c5ef94b080951ce001b86e72e5
CREATE OR REPLACE FUNCTION public.v2_bank(p_key text, p_problem integer, p_school uuid, p_all boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if auth.uid() is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  if v2.current_person() is null then
    raise exception 'بنكُ العبارات لفريق المدرسة — وكلامُك شهادةٌ لا تُملى عليك'; end if;
  if p_school is not null and not v2.my_school(p_school) then
    raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object('id',b.id,'text',b.text_ar,'ord',b.ord,
      'active',b.active,'mine',(b.school_id is not null))
      order by (b.problem_id is null), b.ord),'[]'::jsonb)
  into r from v2.phrase_bank b
  where b.bank_key=p_key and (coalesce(p_all,false) or b.active)
    and (b.school_id is null or b.school_id=p_school)
    and (b.problem_id is null or b.problem_id=p_problem);
  return r;
end $function$
;
