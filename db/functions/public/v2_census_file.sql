-- public.v2_census_file(p_census uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_suggestion text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b958de33575718551abf5f088f96990f
CREATE OR REPLACE FUNCTION public.v2_census_file(p_census uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_suggestion text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c record; me uuid;
begin
  select * into c from v2.behavior_census where id=p_census;
  if c.id is null then raise exception 'تكليفُ الحصر غيرُ موجود'; end if;
  me := v2.current_person();
  if c.assigned_to is distinct from me then raise exception 'هذا التكليفُ لغيرك'; end if;
  if c.state = 'مكتمل' then raise exception 'سُلّم هذا الحصرُ سلفًا'; end if;
  if p_neg is null or array_length(p_neg,1) is null then
    raise exception 'اختر سلوكًا سلبيًّا واحدًا على الأقلّ'; end if;
  if btrim(coalesce(p_causes,''))='' then
    raise exception 'اكتب المسبّبات — فالدليلُ يوجب حصرَها'; end if;

  update v2.behavior_census set
    neg_items=p_neg, pos_items=p_pos,
    negatives=(select string_agg(x.icon||' '||x.text_ar,' · ') from v2.census_items x
                where x.id = any(p_neg)),
    positives=(select string_agg(x.icon||' '||x.text_ar,' · ') from v2.census_items x
                where x.id = any(coalesce(p_pos,'{}'::uuid[]))),
    causes=btrim(p_causes), suggestion=nullif(btrim(coalesce(p_suggestion,'')),''),
    filed_at=now(), state='مكتمل', returned_why=null
   where id=p_census;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (c.school_id,'census',current_date,c.student_id,
      'رفع المكلَّفُ حصرَه','وينظر فيه الوكيل',
      'behavior_census',p_census,'staff',coalesce(c.is_test,false));
  return jsonb_build_object('ok',true,'note','سُلّم الحصرُ — وينظر فيه الوكيل');
end $function$
;
