-- public.v2_year_save(p_school uuid, p_year uuid, p_name text, p_starts date, p_ends date, p_current boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 92ee6299884f9fd8d7a00b54d200603b
CREATE OR REPLACE FUNCTION public.v2_year_save(p_school uuid, p_year uuid, p_name text, p_starts date, p_ends date, p_current boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبطَ السنة الدراسيّة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if btrim(coalesce(p_name,''))='' then raise exception 'اكتب اسمَ السنة — مثل ١٤٤٨هـ'; end if;
  if p_starts is null or p_ends is null then raise exception 'اكتب بدايةَ السنة ونهايتَها'; end if;
  if p_ends <= p_starts then raise exception 'نهايةُ السنة قبل بدايتها'; end if;

  if p_year is null then
    insert into v2.academic_years(school_id,name,starts_on,ends_on,is_current,status)
    values (p_school,btrim(p_name),p_starts,p_ends,coalesce(p_current,false),'open')
    returning id into nid;
  else
    if not exists (select 1 from v2.academic_years where id=p_year and school_id=p_school) then
      raise exception 'هذي السنةُ ليست لمدرستك'; end if;
    if exists (select 1 from v2.academic_years where id=p_year and status='closed') then
      raise exception 'سنةٌ مقفلةٌ لا تُعدَّل'; end if;
    update v2.academic_years set name=btrim(p_name), starts_on=p_starts, ends_on=p_ends,
      is_current=coalesce(p_current,is_current) where id=p_year;
    nid := p_year;
  end if;

  -- سنةٌ جاريةٌ واحدةٌ لا أكثر
  if coalesce(p_current,false) then
    update v2.academic_years set is_current=false
     where school_id=p_school and id<>nid; end if;
  return jsonb_build_object('ok',true,'year',nid);
end $function$
;
