-- public.v2_census_item_save(p_school uuid, p_item uuid, p_polarity text, p_icon text, p_text text, p_hint text, p_ord smallint, p_active boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 11b45ad8792283915244a37b1eb251cb
CREATE OR REPLACE FUNCTION public.v2_census_item_save(p_school uuid, p_item uuid, p_polarity text, p_icon text, p_text text, p_hint text, p_ord smallint, p_active boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare cur record; nid uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبطَ قوائم الحصر');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if p_item is null then
    if coalesce(p_polarity,'') not in ('negative','positive') then
      raise exception 'السلوك: سلبيٌّ أو إيجابيّ'; end if;
    if btrim(coalesce(p_text,''))='' then raise exception 'اكتب نصَّ السلوك'; end if;
    insert into v2.census_items(school_id,polarity,icon,text_ar,hint_ar,ord)
    values (p_school,p_polarity,p_icon,btrim(p_text),
        nullif(btrim(coalesce(p_hint,'')),''),coalesce(p_ord,99))
    returning id into nid;
    return jsonb_build_object('ok',true,'item',nid,'mode','أُضيف');
  end if;
  select * into cur from v2.census_items where id=p_item;
  if cur.id is null then raise exception 'سلوكٌ غيرُ موجود'; end if;
  if cur.school_id is null then
    -- مشتركٌ ⇒ نسخةٌ للمدرسة تحجبه
    insert into v2.census_items(school_id,polarity,icon,text_ar,hint_ar,ord,active,based_on)
    values (p_school,cur.polarity,coalesce(p_icon,cur.icon),
        coalesce(nullif(btrim(coalesce(p_text,'')),''),cur.text_ar),
        coalesce(nullif(btrim(coalesce(p_hint,'')),''),cur.hint_ar),
        coalesce(p_ord,cur.ord),coalesce(p_active,true),cur.id)
    returning id into nid;
    update v2.census_items set active=false where id=p_item and school_id is null
      and exists (select 1 from v2.census_items x where x.based_on=p_item and x.school_id=p_school);
    return jsonb_build_object('ok',true,'item',nid,'mode','عُدّل لمدرستك');
  end if;
  if cur.school_id <> p_school then raise exception 'هذا السلوك لمدرسةٍ أخرى'; end if;
  update v2.census_items set
    icon=coalesce(p_icon,icon),
    text_ar=coalesce(nullif(btrim(coalesce(p_text,'')),''),text_ar),
    hint_ar=coalesce(nullif(btrim(coalesce(p_hint,'')),''),hint_ar),
    ord=coalesce(p_ord,ord), active=coalesce(p_active,active)
   where id=p_item;
  return jsonb_build_object('ok',true,'item',p_item,'mode','عُدّل');
end $function$
;
