-- public.v2_cover_set(p_cover uuid, p_person uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 54e32c35bc6439585a832d7145d69fc6
CREATE OR REPLACE FUNCTION public.v2_cover_set(p_cover uuid, p_person uuid, p_why text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare c v2.period_covers; v_name text;
begin
  select * into c from v2.period_covers where id = p_cover and voided_at is null;
  if c.id is null then raise exception 'لا سجلَّ تغطيةٍ بهذا الرقم'; end if;
  perform v2.assert_role(array['principal','deputy_academic','deputy','deputy_school'],
                         'تبديل مغطّي الحصّة');
  perform v2.assert_my_school(c.school_id, 'تبديل مغطّي الحصّة');
  if coalesce(btrim(p_why),'') = '' then
    raise exception 'التبديلُ اليدويُّ يَلزمه سببٌ مكتوب — ليُقرأ بعد حين';
  end if;
  if p_person is not null then
    if exists (select 1 from v2.staff_absences sa
                where sa.school_id = c.school_id and sa.person_id = p_person and sa.on_date = c.on_date
                  and sa.voided_at is null
                  and (sa.from_period is null or c.period_no >= sa.from_period)
                  and (sa.to_period   is null or c.period_no <= sa.to_period)) then
      raise exception 'لا يُغطّي غائبٌ';
    end if;
    if exists (select 1 from v2.timetable t
                where t.school_id = c.school_id and t.weekday = c.weekday and t.period_no = c.period_no
                  and t.person_id = p_person and t.slot_kind in ('teaching','activity')) then
      raise exception 'عنده حصّةٌ في هذا الوقت — ولا يُترك فصلٌ ليُغطّى فصل';
    end if;
    if exists (select 1 from v2.period_covers c2
                where c2.school_id = c.school_id and c2.on_date = c.on_date and c2.period_no = c.period_no
                  and c2.cover_person = p_person and c2.voided_at is null and c2.id <> c.id) then
      raise exception 'هو مُسنَدٌ إليه في هذه الحصّة سلفًا';
    end if;
    select v2.fn_display_name(full_name) into v_name from v2.people where id = p_person;
  end if;

  update v2.period_covers
     set cover_person = p_person,
         cover_basis = case when p_person is null then 'none' else 'manual' end,
         decided = case when p_person is null then 'gap' else 'manual' end,
         decided_by = v2.current_person(), decided_at = now(),
         why_ar = case when p_person is null then null else btrim(p_why) end,
         gap_reason_ar = case when p_person is null then btrim(p_why) else null end
   where id = p_cover;
  return coalesce('أُسندت إلى ' || v_name, 'رُفعت التغطية وبقيت الحصّةُ مكشوفةً بسببها المكتوب');
end $function$
;
