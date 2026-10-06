-- public.v2_forms_catalog(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6ed5bac1dd136611bc2913542910d498
CREATE OR REPLACE FUNCTION public.v2_forms_catalog(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  if auth.uid() is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  if p_school is not null and not v2.my_school(p_school) then
    raise exception 'ليست مدرستك'; end if;
  select coalesce(jsonb_agg(jsonb_build_object(
      'no',f.form_no,'no_ar',v2.ar_num(f.form_no),'title',f.title_ar,
      'group', case when f.form_no between 1 and 17 then 'نماذج السلوك والمواظبة'
                    when f.form_no >= 101 then 'نماذج الحماية' else 'أخرى' end,
      'open', (select count(*) from v2.form_entries e
                where e.form_no=f.form_no
                  and (p_school is null or e.school_id=p_school)
                  and e.status in ('draft','final')),
      'signed', (select count(*) from v2.form_entries e
                where e.form_no=f.form_no
                  and (p_school is null or e.school_id=p_school)
                  and e.status='signed'))
      order by f.form_no),'[]'::jsonb)
  into r from v2.official_forms f;
  return r;
end $function$
;
