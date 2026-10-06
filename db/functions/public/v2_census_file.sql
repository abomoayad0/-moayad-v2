-- public.v2_census_file(p_census uuid, p_positives text, p_negatives text, p_causes text, p_suggestion text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 89ae642f37d0c7d47ac162cb6ee1d34f
CREATE OR REPLACE FUNCTION public.v2_census_file(p_census uuid, p_positives text, p_negatives text, p_causes text, p_suggestion text)
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
  if btrim(coalesce(p_positives,''))='' then
    raise exception 'اكتب السلوكيّاتِ الإيجابيّة — فالحصرُ يجمع الإيجابيَّ والسلبيَّ معًا'; end if;
  if btrim(coalesce(p_negatives,''))='' then
    raise exception 'اكتب السلوكيّاتِ السلبيّة'; end if;
  if btrim(coalesce(p_causes,''))='' then
    raise exception 'اكتب المسبّبات — فالدليلُ يوجب حصرَها'; end if;

  update v2.behavior_census set
    positives=btrim(p_positives), negatives=btrim(p_negatives),
    causes=btrim(p_causes), suggestion=nullif(btrim(coalesce(p_suggestion,'')),''),
    filed_at=now(), state='مكتمل', returned_why=null
   where id=p_census;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (c.school_id,'census',current_date,c.student_id,
      'سُلّم حصرُ السلوكيّات','الإيجابيُّ والسلبيُّ ومسبّباتُه',
      'behavior_census',p_census,'staff',coalesce(c.is_test,false));
  return jsonb_build_object('ok',true,'note','سُلّم الحصرُ — وينظر فيه الوكيل');
end $function$
;
