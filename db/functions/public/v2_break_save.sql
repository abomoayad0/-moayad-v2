-- public.v2_break_save(p_school uuid, p_break uuid, p_kind text, p_label text, p_starts time without time zone, p_ends time without time zone, p_after smallint, p_needs_duty boolean, p_min_staff smallint, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2d4b5a864eca2bf7a738ebd122221d89
CREATE OR REPLACE FUNCTION public.v2_break_save(p_school uuid, p_break uuid, p_kind text, p_label text, p_starts time without time zone, p_ends time without time zone, p_after smallint, p_needs_duty boolean, p_min_staff smallint, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare nid uuid; clash record;
begin
  perform v2.assert_role(array['principal','deputy_students','deputy','deputy_academic'],
                         'ضبطَ فترات اليوم');
  if not v2.my_school(p_school) then raise exception 'ليست مدرستك'; end if;
  if coalesce(p_kind,'') not in ('فسحة','صلاة','اصطفاف','انصراف','أخرى') then
    raise exception 'النوع: فسحةٌ · صلاةٌ · اصطفافٌ · انصرافٌ · أخرى'; end if;
  if btrim(coalesce(p_label,''))='' then raise exception 'اكتب اسمَ الفترة'; end if;
  if p_starts is null or p_ends is null then raise exception 'اكتب بدايةَ الفترة ونهايتَها'; end if;
  if p_ends <= p_starts then raise exception 'نهايةُ الفترة قبل بدايتها'; end if;

  -- 🔑 لا تتداخل فترةٌ مع حصّة
  select s.period_no, s.starts_at, s.ends_at into clash
    from v2.period_slots s
   where s.school_id=p_school
     and (p_starts, p_ends) overlaps (s.starts_at, s.ends_at) limit 1;
  if clash.period_no is not null then
    raise exception 'تتداخل مع الحصّة % (% — %)',
      v2.ar_num(clash.period_no), v2.time_ar(clash.starts_at), v2.time_ar(clash.ends_at); end if;

  -- ولا مع فترةٍ أخرى
  if exists (select 1 from v2.break_slots b
              where b.school_id=p_school and b.active
                and b.id is distinct from p_break
                and (p_starts, p_ends) overlaps (b.starts_at, b.ends_at)) then
    raise exception 'تتداخل مع فترةٍ أخرى في اليوم'; end if;

  if p_break is null then
    insert into v2.break_slots(school_id,kind,label_ar,starts_at,ends_at,after_period,
        needs_duty,min_staff,note_ar)
    values (p_school,p_kind,btrim(p_label),p_starts,p_ends,p_after,
        coalesce(p_needs_duty,true),p_min_staff,nullif(btrim(coalesce(p_note,'')),''))
    returning id into nid;
    return jsonb_build_object('ok',true,'break',nid,'mode','أُضيفت');
  end if;
  update v2.break_slots set kind=p_kind, label_ar=btrim(p_label),
    starts_at=p_starts, ends_at=p_ends, after_period=p_after,
    needs_duty=coalesce(p_needs_duty,needs_duty), min_staff=p_min_staff,
    note_ar=nullif(btrim(coalesce(p_note,'')),'')
   where id=p_break and school_id=p_school;
  if not found then raise exception 'هذي الفترةُ ليست لمدرستك'; end if;
  return jsonb_build_object('ok',true,'break',p_break,'mode','عُدّلت');
end $function$
;
