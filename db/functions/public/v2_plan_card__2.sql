-- public.v2_plan_card(p_school uuid, p_grade smallint, p_subject text, p_term smallint, p_person uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 743a58058392233010cc66bcb1360d09
CREATE OR REPLACE FUNCTION public.v2_plan_card(p_school uuid, p_grade smallint, p_subject text, p_term smallint, p_person uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_plan uuid; v_exam smallint; r jsonb;
begin
  perform v2.assert_my_school(p_school,'قراءةَ توزيع المنهج');

  select id into v_plan from v2.lesson_plans
   where school_id=p_school and term_no=p_term and grade=p_grade
     and subject_ar=btrim(p_subject) and owner_person=p_person;
  if v_plan is null then
    return jsonb_build_object('plan',null,'owner',p_person,
      'summary_ar','لا توزيعَ لهذا المعلّم في هذي المادّة وهذا الفصل بعد — ويُحسب آليًّا بزرٍّ واحد',
      'fix','v2_plan_build');
  end if;

  select min(x.week_no) into v_exam from v2.school_weeks(p_school) x
   where x.term_no=p_term and x.is_exam;

  select jsonb_build_object(
    'plan', p.id, 'grade', p.grade, 'subject_ar', p.subject_ar, 'term_no', p.term_no,
    'owner', p.owner_person,
    'owner_ar', (select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=p.owner_person),
    'sections', (select coalesce(jsonb_agg(jsonb_build_object(
                    'section', s.section_id, 'label_ar', s.label_ar) order by s.label_ar),'[]'::jsonb)
                 from v2.plan_sections(p.id) s),
    'sections_n', (select count(*) from v2.plan_sections(p.id)),
    'status', p.status, 'source', p.source, 'build_no', p.build_no,
    'is_locked', p.is_locked, 'lock_why', p.lock_why,
    'review_path', p.review_path, 'approved_without_review', p.approved_without_review,
    'note_ar', p.note_ar,
    'exam_week', v_exam,
    'counts', jsonb_build_object(
      'items',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id),
      'done',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id and i.state='done'),
      'deferred',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id and i.state='deferred'),
      'lost',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id and i.state='lost'),
      'unplaced',(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id and i.week_no is null),
      'section_pairs_done',(select count(*) from v2.lesson_item_progress pr
                             join v2.lesson_plan_items i2 on i2.id=pr.item_id
                            where i2.plan_id=p.id and pr.voided_at is null and pr.state='done'),
      'section_pairs_total',(select count(*) from v2.lesson_plan_items i3
                              where i3.plan_id=p.id and i3.week_no is not null)
                            * greatest((select count(*) from v2.plan_sections(p.id)),1)),
    'weeks', (select coalesce(jsonb_agg(q order by q->>'week_no'),'[]'::jsonb) from (
        select jsonb_build_object('week_no', x.week_no, 'from_h', x.from_h, 'to_h', x.to_h,
          'is_current',(current_date between x.from_g and x.to_g),
          'is_exam', x.is_exam,
          'items', (select coalesce(jsonb_agg(jsonb_build_object(
                      'lesson', i.lesson_id, 'title_ar', l.title_ar,
                      'periods', i.periods, 'ord', i.ord, 'state', i.state,
                      'kind', coalesce(i.kind_override, l.kind, 'lesson'),
                      'kind_is_mine', (i.kind_override is not null),
                      'done_on', i.done_on, 'why', i.state_why,
                      'moved', (i.moved_at is not null), 'move_why', i.move_why,
                      'page_from', i.page_from, 'page_to', i.page_to,
                      'unit_ar', u.title_ar,
                      'by_section', (select coalesce(jsonb_agg(jsonb_build_object(
                           'section', s.section_id, 'label_ar', s.label_ar,
                           'state', coalesce((select pr.state from v2.lesson_item_progress pr
                                               where pr.item_id=i.id and pr.section_id=s.section_id
                                                 and pr.voided_at is null),'planned'),
                           'on_date', (select pr.on_date from v2.lesson_item_progress pr
                                        where pr.item_id=i.id and pr.section_id=s.section_id
                                          and pr.voided_at is null),
                           'why', (select pr.why_ar from v2.lesson_item_progress pr
                                    where pr.item_id=i.id and pr.section_id=s.section_id
                                      and pr.voided_at is null))
                           order by s.label_ar),'[]'::jsonb)
                         from v2.plan_sections(p.id) s),
                      'done_sections', (select count(*) from v2.lesson_item_progress pr
                                         where pr.item_id=i.id and pr.voided_at is null
                                           and pr.state='done')) order by i.ord),'[]'::jsonb)
                    from v2.lesson_plan_items i
                    join v2.curriculum_lessons l on l.id=i.lesson_id
                    join v2.curriculum_units u on u.id=l.unit_id
                   where i.plan_id=p.id and i.week_no = x.week_no)) q
          from v2.school_weeks(p_school) x where x.term_no=p_term) z),
    'pending', (select coalesce(jsonb_agg(jsonb_build_object(
                  'lesson', i.lesson_id,'title_ar', l.title_ar,'periods', i.periods) order by i.ord),'[]'::jsonb)
                from v2.lesson_plan_items i join v2.curriculum_lessons l on l.id=i.lesson_id
               where i.plan_id=p.id and i.week_no is null),
    'summary_ar','توزيعُ «'||p.subject_ar||'» للصفّ '||p.grade||' · الفصلُ '||p.term_no
      || ' · للمعلّم '||(select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=p.owner_person)
      || ' و'||v2.ar_count((select count(*) from v2.plan_sections(p.id)),
                           'فصلٍ واحد','فصلين','فصولٍ','فصلًا')||' — '
      || case p.status when 'draft' then 'مسوّدةٌ محسوبةٌ لم تُعلَن'
                       when 'prepared' then 'أعدَّها المعلّمُ وتنتظر المراجعة'
                       when 'reviewed' then 'رُوجعت وتنتظر اعتمادَ الوكيل'
                       else 'معتمدة' end
      || ' · تمّ في فصولك كلِّها '||(select count(*) from v2.lesson_plan_items i
                        where i.plan_id=p.id and i.state='done')
      || ' من '||(select count(*) from v2.lesson_plan_items i where i.plan_id=p.id),
    'note_ar','التوزيعُ لك ويغطّي فصولَك كلَّها، والإنجازُ يُرصد لكلّ فصلٍ على حدة — '
      ||'والبندُ لا يتمّ حتى يتمّ في فصولك كلِّها. '
      ||'والبنودُ الموسومةُ اختبارًا أو مراجعةً أو تهيئةً ليست دروسًا تُدرَّس وتأخذ حصّتَها. '
      ||'وأسبوعُ اختبارِ نهاية الفصل لا بندَ فيه، وينتهي المنهجُ في الأسبوع الذي قبله.'
  ) into r from v2.lesson_plans p where p.id=v_plan;
  return r;
end $function$
;
