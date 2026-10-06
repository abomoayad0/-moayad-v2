-- public.v2_term_save(p_school uuid, p_year uuid, p_term uuid, p_number smallint, p_starts date, p_ends date, p_current boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 96e16f0eb13875fc3213ec0c1679615b
CREATE OR REPLACE FUNCTION public.v2_term_save(p_school uuid, p_year uuid, p_term uuid, p_number smallint, p_starts date, p_ends date, p_current boolean)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; y record;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبطَ الفصول الدراسيّة');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  select * into y from v2.academic_years where id=p_year and school_id=p_school;
  if y.id is null then raise exception 'هذي السنةُ ليست لمدرستك'; end if;
  if y.status='closed' then raise exception 'سنةٌ مقفلةٌ لا تُعدَّل'; end if;
  if p_number is null or p_number not between 1 and 3 then
    raise exception 'رقمُ الفصل: ١ أو ٢ أو ٣'; end if;
  if p_starts is null or p_ends is null then raise exception 'اكتب بدايةَ الفصل ونهايتَه'; end if;
  if p_ends <= p_starts then raise exception 'نهايةُ الفصل قبل بدايته'; end if;
  if p_starts < y.starts_on or p_ends > y.ends_on then
    raise exception 'الفصلُ خارجَ حدود السنة (% — %)', y.starts_on, y.ends_on; end if;
  if exists (select 1 from v2.terms t where t.year_id=p_year
              and t.id is distinct from p_term
              and (p_starts, p_ends) overlaps (t.starts_on, t.ends_on)) then
    raise exception 'هذي المدّةُ تتداخل مع فصلٍ آخر'; end if;

  if p_term is null then
    if exists (select 1 from v2.terms where year_id=p_year and number=p_number) then
      raise exception 'الفصلُ رقم % مسجَّلٌ سلفًا في هذي السنة', p_number; end if;
    insert into v2.terms(year_id,number,starts_on,ends_on,is_current)
    values (p_year,p_number,p_starts,p_ends,coalesce(p_current,false))
    returning id into nid;
  else
    update v2.terms set number=p_number, starts_on=p_starts, ends_on=p_ends,
      is_current=coalesce(p_current,is_current) where id=p_term and year_id=p_year;
    if not found then raise exception 'فصلٌ غيرُ موجودٍ في هذي السنة'; end if;
    nid := p_term;
  end if;

  if coalesce(p_current,false) then
    update v2.terms set is_current=false where year_id=p_year and id<>nid; end if;
  return jsonb_build_object('ok',true,'term',nid);
end $function$
;
