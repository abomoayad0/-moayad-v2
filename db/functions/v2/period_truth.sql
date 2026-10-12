-- v2.period_truth(p_school uuid, p_section uuid, p_period smallint, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f6bedc775996c75228f9a8e3d872492d
CREATE OR REPLACE FUNCTION v2.period_truth(p_school uuid, p_section uuid, p_period smallint, p_date date)
 RETURNS TABLE(person_id uuid, person_ar text, subject_ar text, basis text, why_ar text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  v_wd smallint := extract(dow from p_date)::smallint;
  v_slot uuid; v_owner uuid; v_subj text; v_sw uuid;
  v_cover uuid; v_gap text; v_absent uuid; v_found boolean := false;
begin
  select t.id, t.person_id, t.subject_ar into v_slot, v_owner, v_subj
    from v2.timetable t
   where t.school_id = p_school and t.section_id = p_section
     and t.weekday = v_wd and t.period_no = p_period
     and t.slot_kind in ('teaching','activity')
   limit 1;
  if v_slot is null then return; end if;

  basis := 'schedule';
  why_ar := 'من الجدول المعتمد';

  -- ① تبديلٌ معتمدٌ يغيّر صاحبَ الخانة
  v_sw := v2.swap_of(p_school, p_date, v_slot);
  if v_sw is not null then
    why_ar := 'تبديلٌ معتمدٌ مع ' || coalesce(
      (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id = v_owner),'—');
    v_owner := v_sw;
    basis := 'swap';
    v_subj := coalesce((select t2.subject_ar from v2.timetable t2
                         where t2.school_id=p_school and t2.person_id=v_owner
                           and t2.section_id=p_section and t2.slot_kind='teaching' limit 1), v_subj);
  end if;

  -- ② ثمّ تغطيةُ غيابٍ مسجَّلةٌ تسبق كلَّ شيءٍ — فهي قرارُ الصباح
  select c.cover_person, c.gap_reason_ar, c.absent_person
    into v_cover, v_gap, v_absent
    from v2.period_covers c
   where c.school_id = p_school and c.on_date = p_date and c.period_no = p_period
     and c.section_id = p_section and c.voided_at is null
   limit 1;
  v_found := found;

  if v_found and v_cover is not null then
    v_owner := v_cover;
    basis := 'cover';
    why_ar := 'تغطيةُ غياب ' || coalesce(
      (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id = v_absent),'—');
  elsif v_found and v_gap is not null then
    v_owner := null;
    basis := 'gap';
    why_ar := v_gap;
  end if;

  person_id := v_owner;
  person_ar := coalesce((select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=v_owner),
                        '— بلا معلّم');
  subject_ar := v_subj;
  return next;
end $function$
;
