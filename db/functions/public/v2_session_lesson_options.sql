-- public.v2_session_lesson_options(p_session uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2fab7e4918a9c607460b48cc4aee7a66
CREATE OR REPLACE FUNCTION public.v2_session_lesson_options(p_session uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare s record; grd smallint; pl uuid; st text; me uuid := v2.current_person();
begin
  if me is null then raise exception 'لا بدّ من تسجيل الدخول'; end if;
  select * into s from v2.class_sessions where id = p_session;
  if s.id is null then raise exception 'لا جلسةَ بهذا المُعرّف'; end if;
  perform v2.assert_my_school(s.school_id, 'بنودَ الدرس لهذي الحصّة');
  select cs.grade into grd from v2.class_sections cs where cs.id = s.section_id;

  select p.id, p.status into pl, st from v2.lesson_plans p
   where p.school_id = s.school_id and p.grade = grd and p.subject_ar = s.subject_ar
     and p.term_no = v2.fn_term_of(s.school_id, s.on_date)
     and (p.year_id is null or p.year_id = (select y.id from v2.academic_years y
                                             where y.school_id = s.school_id and y.is_current limit 1))
   order by p.approved_at desc nulls last, p.created_at desc
   limit 1;

  return jsonb_build_object(
    'session', p_session,
    'grade_ar', v2.grade_ar(grd),
    'subject_ar', s.subject_ar,
    'plan', pl,
    'plan_status', st,
    'plan_status_ar', case st when 'approved' then 'معتمد' when 'draft' then 'مسوّدة'
                              when 'prepared' then 'أُعلن إعدادُه' when 'review' then 'تحت المراجعة'
                              when 'locked' then 'مُقفَل' else st end,
    'current_item', s.lesson_item,
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object(
          'item', i.id,
          'week_no', i.week_no,
          'title_ar', cl.title_ar,
          'unit_ar', (select u.title_ar from v2.curriculum_units u where u.id = cl.unit_id),
          'periods', i.periods,
          'periods_used', i.periods_used,
          'state', i.state,
          'state_ar', case i.state when 'done' then 'أُنجز' when 'planned' then 'مخطَّطٌ له'
                                   else i.state end,
          'page_from', i.page_from, 'page_to', i.page_to,
          'is_current', i.id = s.lesson_item,
          'suggested', i.state = 'planned')
        order by i.week_no nulls last, i.ord nulls last)
      from v2.lesson_plan_items i
      join v2.curriculum_lessons cl on cl.id = i.lesson_id
      where i.plan_id = pl and i.merged_into is null), '[]'::jsonb),
    'note_ar', case
      when pl is null then 'لا توزيعَ منهجٍ لهذي المادّة في هذا الصفّ — فتسميةُ الدرس نصٌّ حرٌّ حتى يُبنى'
      when st = 'approved' then 'البنودُ من توزيع المنهج المعتمد — والمخطَّطُ له يُقترح، والمُنجَزُ يُعرض ولا يُعاد'
      else 'البنودُ من توزيعٍ حالُه «'||
           (case st when 'draft' then 'مسوّدة' when 'prepared' then 'أُعلن إعدادُه'
                    when 'review' then 'تحت المراجعة' when 'locked' then 'مُقفَل' else st end)||
           '» لا معتمَد — فاعرضها وبيِّن حالَه' end);
end $function$
;
