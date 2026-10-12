-- public.v2_remedial_board(p_school uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5bf761e8cf56c4e6436a69050b0b56da
CREATE OR REPLACE FUNCTION public.v2_remedial_board(p_school uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare tm smallint; r jsonb; n_wait int; n_run int; n_eval int;
begin
  perform v2.assert_my_school(p_school,'قراءةَ لوحة الخطط العلاجيّة');
  perform v2.assert_role(array['deputy_academic','deputy','principal','counselor','deputy_students'],
    'قراءةَ لوحة الخطط العلاجيّة');
  tm := coalesce(p_term, v2.fn_term_of(p_school, current_date));

  select coalesce(jsonb_agg(jsonb_build_object(
      'plan', p.id,
      'title_ar', p.title_ar,
      'subject_ar', p.subject_ar,
      'kind_ar', case p.kind when 'individual' then 'فرديّة' else 'جماعيّة' end,
      'owner_ar', coalesce(v2.fn_display_name(pe.full_name),'—'),
      'students_n', case when p.kind='individual' then 1
                    else (select count(*)::int from v2.remedial_members m
                           where m.plan_id=p.id and m.removed_at is null) end,
      'periods_proposed', (select count(*)::int from v2.remedial_periods rp
                            where rp.plan_id=p.id and rp.state='proposed'),
      'periods_approved', (select count(*)::int from v2.remedial_periods rp
                            where rp.plan_id=p.id and rp.state='approved'),
      'state', p.state,
      'state_ar', case p.state
        when 'draft' then case when p.kind='group' then 'تنتظر مراجعةَ لجنة التوجيه' else 'تنتظر اعتمادَ الوكيل' end
        when 'reviewed' then 'راجعتها اللجنةُ وتنتظر اعتمادَ الوكيل'
        when 'approved' then 'معتمدةٌ وحصصُها في الجدول'
        when 'running'  then 'جاريةٌ'
        else 'مُقيَّمةٌ — '||case when p.improved then 'تحسّنت الحالة' else 'لم تتحسّن' end end,
      'enrich_needed', coalesce(p.enrich_needed,false),
      'waiting_ar', case
        when p.kind='group' and p.reviewed_at is null then 'لجنةُ التوجيه الطلابيّ'
        when p.approved_at is null then 'الوكيلُ للشؤون التعليميّة'
        when p.evaluated_at is null then 'تقييمُ النتائج'
        else '—' end) order by p.created_at desc),'[]'::jsonb) into r
    from v2.remedial_plans p
    left join v2.people pe on pe.id=p.owner_person
   where p.school_id=p_school and p.term_no=tm and p.voided_at is null;

  select count(*) filter (where p.approved_at is null),
         count(*) filter (where p.approved_at is not null and p.evaluated_at is null),
         count(*) filter (where p.evaluated_at is not null)
    into n_wait, n_run, n_eval
    from v2.remedial_plans p
   where p.school_id=p_school and p.term_no=tm and p.voided_at is null;

  return jsonb_build_object('rows',r,'count',jsonb_array_length(r),'term',tm,
    'waiting',n_wait,'running',n_run,'evaluated',n_eval,
    'summary_ar', case when jsonb_array_length(r)=0 then 'لا خطّةَ علاجيّةً في هذا الفصل'
      else v2.ar_count(jsonb_array_length(r),'خطّةٌ واحدة','خطّتان','خططٍ','خطّةً')
        ||' — '||v2.ar_num(n_wait)||' تنتظر، و'||v2.ar_num(n_run)||' معتمدةٌ بلا تقييم، و'
        ||v2.ar_num(n_eval)||' مُقيَّمة' end,
    'note_ar','والاعتمادُ للوكيل للشؤون التعليميّة · ومراجعةُ الجماعيّة للجنة التوجيه الطلابيّ — '
      ||v2.cite_of('remedial.approve'));
end $function$
;
