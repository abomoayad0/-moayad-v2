-- public.v2_my_day(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3d0608c4ad261b43cbc38749ab6b7913
CREATE OR REPLACE FUNCTION public.v2_my_day(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_me uuid := v2.current_person(); r jsonb;
begin
  perform v2.assert_my_school(p_school,'قراءةَ يومك');
  select coalesce(jsonb_agg(jsonb_build_object(
      'period', e.period_no,
      'section_ar', coalesce((select cs.label_ar from v2.class_sections cs where cs.id=e.section_id),'—'),
      'subject_ar', coalesce(e.subject_ar,'—'),
      'basis', e.basis,
      'basis_ar', case e.basis when 'swap' then 'جاءتك بتبديلٍ معتمدٍ مع '||coalesce(e.from_ar,'—')
                               else 'من جدولك' end) order by e.period_no),'[]'::jsonb) into r
    from v2.effective_periods(p_school, v_me, p_date) e;

  -- وتغطياتُه اليومَ تُضاف
  select r || coalesce((select jsonb_agg(jsonb_build_object(
      'period', c.period_no,
      'section_ar', coalesce(cs.label_ar,'—'),
      'subject_ar', coalesce(c.subject_ar,'—'),
      'basis','cover',
      'basis_ar','تغطيةُ غياب '||coalesce(v2.fn_display_name(pa.full_name),'—')))
      from v2.period_covers c
      left join v2.class_sections cs on cs.id=c.section_id
      left join v2.people pa on pa.id=c.absent_person
     where c.school_id=p_school and c.on_date=p_date and c.cover_person=v_me
       and c.voided_at is null),'[]'::jsonb) into r;

  -- وحصصُه العلاجيّةُ المعتمدةُ تُضاف · س-٩-ا-٢
  select r || coalesce((select jsonb_agg(jsonb_build_object(
      'period', d.period_no,
      'section_ar', case when d.kind='individual' then 'طالبٌ واحد'
                         else v2.ar_count(d.members_n,'طالبٌ واحد','طالبان','طلّابٍ','طالبًا') end,
      'subject_ar', coalesce(d.subject_ar,'—'),
      'basis','remedial',
      'plan', d.plan_id,
      'basis_ar','حصّةٌ علاجيّةٌ معتمدةٌ — خطّةُ «'||d.title_ar||'»'
        ||case when d.from_standby then ' · من خانة انتظارك' else ' · زيادةً على نصابك' end))
      from v2.remedial_day(p_school, v_me, p_date) d),'[]'::jsonb) into r;

  return jsonb_build_object('rows',r,'count',jsonb_array_length(r),
    'summary_ar', case when jsonb_array_length(r)=0 then 'لا حصصَ لك في هذا اليوم'
      else v2.ar_count(jsonb_array_length(r),'حصّةٌ واحدة','حصّتان','حصصٍ','حصّةً')
           ||' — بعد التبديل والتغطية والعلاجيّة' end);
end $function$
;
