-- public.v2_plan_build(p_school uuid, p_grade smallint, p_subject text, p_term smallint, p_person uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b218965f33d73238f7ca3d1271cd72e6
CREATE OR REPLACE FUNCTION public.v2_plan_build(p_school uuid, p_grade smallint, p_subject text, p_term smallint, p_person uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  v_plan uuid; v_status text; v_locked boolean; v_build smallint;
  v_rep uuid; v_slots_wk int; v_per_total int := 0; v_need int := 0;
  v_weeks int := 0; v_placed int := 0; v_unplaced int := 0;
  v_exam_wk smallint; v_exam_from text; v_last_wk smallint;
  v_cap_term int := 0; v_slack int;
  v_cap int; v_ord smallint := 0; v_me uuid := v2.current_person();
  v_teacher boolean := false; v_mapped text[]; v_owner uuid; v_owner_ar text;
  v_lid uuid; v_ltitle text; v_lper smallint; v_lkind text;
  v_secs int; w record; v_preview jsonb := '[]'::jsonb; v_wk_items text;
begin
  perform v2.assert_my_school(p_school,'حسابَ توزيع المنهج');

  begin
    perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
      'admin_assistant','info_registrar'],'حسابَ توزيع المنهج');
  exception when others then
    perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher'],
      'حسابَ توزيع المنهج');
    v_teacher := true;
  end;

  -- 🔑 التوزيعُ للمعلّم في مادّته وصفّه — فلا خطّةَ بلا صاحب
  if v_teacher then
    if p_person is not null and p_person <> v_me then
      raise exception 'لا تُحسب خطّةُ معلّمٍ آخر — خطّتُك لك، والإدارةُ تحسب لغيرك';
    end if;
    v_owner := v_me;
  else
    if p_person is null then
      raise exception 'سمِّ المعلّم — فالتوزيعُ للمعلّم في مادّته وصفّه، ولا يُحسب توزيعٌ بلا صاحب';
    end if;
    v_owner := p_person;
  end if;

  if not exists (select 1 from v2.timetable t join v2.class_sections c on c.id=t.section_id
                  where t.school_id=p_school and t.person_id=v_owner and c.grade=p_grade
                    and t.subject_ar=btrim(p_subject) and t.slot_kind='teaching') then
    raise exception 'ليست له حصصُ «%» في الصفّ % في جدول مدرستك — والتوزيعُ يُحسب على الجدول',
      btrim(p_subject), p_grade;
  end if;
  select v2.fn_display_name(full_name) into v_owner_ar from v2.people where id=v_owner;

  if not exists (select 1 from v2.curriculum_term_split s
                  where s.grade=p_grade and s.subject_ar=btrim(p_subject)) then
    perform v2.term_split_ensure(p_grade, btrim(p_subject));
  end if;
  if p_term not in (1,2) then
    raise exception 'الفصلُ الدراسيُّ اثنان لا ثلاثة — فالمقبولُ ١ أو ٢';
  end if;

  if p_term = 2 and not exists (
       select 1 from v2.lesson_plans p
        where p.school_id=p_school and p.grade=p_grade and p.owner_person=v_owner
          and p.subject_ar=btrim(p_subject) and p.term_no=1) then
    raise exception 'ابْنِ الفصلَ الأوّلَ أوّلًا — فأكثرُ وحدات المنهج بلا فصلٍ مُسجَّل، وترتيبُها يُستنتج من بثّ الفصل الأوّل. ولو بُني الثاني قبله أخذ دروسَ الأوّل.';
  end if;

  select min(x.week_no) into v_exam_wk
    from v2.school_weeks(p_school) x where x.term_no=p_term and x.is_exam;
  select x.from_h into v_exam_from
    from v2.school_weeks(p_school) x where x.term_no=p_term and x.week_no=v_exam_wk;

  select count(*), max(x.week_no) into v_weeks, v_last_wk
    from v2.school_weeks(p_school) x
   where x.term_no=p_term and not x.is_exam
     and (v_exam_wk is null or x.week_no < v_exam_wk);
  if coalesce(v_weeks,0) = 0 then
    raise exception 'لا أسابيعَ للتوزيع في الفصل % — فراجِع تقويمَ مدرستك أوّلًا', p_term;
  end if;

  -- 🔑 السعةُ من فصولِ هذا المعلّم وحدَه
  select t.section_id, count(*) into v_rep, v_slots_wk
    from v2.timetable t join v2.class_sections c on c.id=t.section_id
   where t.school_id=p_school and c.grade=p_grade and t.person_id=v_owner
     and t.subject_ar=btrim(p_subject) and t.slot_kind='teaching'
   group by t.section_id order by count(*) desc limit 1;

  select count(distinct t.section_id) into v_secs
    from v2.timetable t join v2.class_sections c on c.id=t.section_id
   where t.school_id=p_school and c.grade=p_grade and t.person_id=v_owner
     and t.subject_ar=btrim(p_subject) and t.slot_kind='teaching';

  select array_agg(m.curriculum_subject_ar) into v_mapped
    from v2.curriculum_subject_map m where m.plan_subject_ar = btrim(p_subject);

  select count(*), coalesce(sum(coalesce(l.periods,1)),0) into v_need, v_per_total
    from v2.curriculum_units u
    join v2.curriculum_lessons l on l.unit_id=u.id
   where u.grade=p_grade and u.term_no = p_term
     and (u.subject_ar = btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')))
     and not exists (select 1 from v2.lesson_plan_items i9
                       join v2.lesson_plans p9 on p9.id=i9.plan_id
                      where p9.school_id=p_school and p9.grade=p_grade
                        and p9.owner_person=v_owner
                        and p9.subject_ar=btrim(p_subject) and p9.term_no <> p_term
                        and i9.lesson_id=l.id and i9.week_no is not null);

  if v_need = 0 then
    raise exception 'لا دروسَ منقولةً لمادّة «%» في الصفّ % للفصل % — فلا يُحسب توزيعٌ على فراغ',
      btrim(p_subject), p_grade, p_term;
  end if;

  select id, status, is_locked, build_no into v_plan, v_status, v_locked, v_build
    from v2.lesson_plans
   where school_id=p_school and term_no=p_term and grade=p_grade
     and subject_ar=btrim(p_subject) and owner_person=v_owner;

  if v_plan is not null then
    if v_locked then
      raise exception 'خطّةُ هذي المادّة مُقفلةٌ — ولا يُعاد حسابُها حتى يُفتح الإقفال';
    end if;
    if v_status = 'approved' then
      raise exception 'خطّةُ هذي المادّة معتمدةٌ — وإعادةُ حسابها تنقض اعتمادَ الوكيل. فاطلب فتحَها أوّلًا';
    end if;
    update v2.lesson_plans
       set source='محسوب', status='draft', built_at=now(), build_no=coalesce(v_build,0)+1,
           prepared_by=null, prepared_at=null, review_path=null, reviewed_by=null,
           reviewed_at=null, approved_by=null, approved_at=null, approved_without_review=false
     where id=v_plan;
  else
    begin
      insert into v2.lesson_plans (school_id, year_id, term_no, grade, subject_ar,
          owner_person, status, source, built_at, build_no)
      values (p_school,
              (select y.id from v2.academic_years y where y.school_id=p_school and y.is_current limit 1),
              p_term, p_grade, btrim(p_subject), v_owner, 'draft','محسوب', now(), 1)
      returning id into v_plan;
    exception when unique_violation then
      raise exception 'قفلٌ قديمٌ في القاعدة يمنع توزيعًا ثانيًا لهذا الصفّ والمادّة — وهذا الصفُّ له معلّمٌ آخرُ بتوزيعه. والتوزيعُ صار للمعلّم بأمر مفرح، وفتحُ القفل سطرٌ واحدٌ ينفّذه مسؤولُ الاستضافة في محرّر الاستعلام: drop index v2.ux_lesson_plans_one';
    end;
  end if;

  update v2.lesson_plan_items set week_no = null
   where plan_id = v_plan and state = 'planned';

  for w in
    select x.week_id, x.week_no, x.from_h, x.to_h,
           (select count(*) from v2.timetable t
              join v2.calendar_days d on d.week_id = x.week_id and d.day_kind='study'
                   and extract(dow from d.on_g)::int = t.weekday
             where t.school_id=p_school and t.section_id=v_rep
               and t.subject_ar=btrim(p_subject) and t.slot_kind='teaching') as cap
      from v2.school_weeks(p_school) x
     where x.term_no=p_term and not x.is_exam
       and (v_exam_wk is null or x.week_no < v_exam_wk)
     order by x.week_no
  loop
    v_cap_term := v_cap_term + coalesce(w.cap,0);
    v_cap := coalesce(w.cap, 0);
    v_wk_items := null;
    while v_cap > 0 loop
      v_lid := null; v_ltitle := null; v_lper := null; v_lkind := null;
      select l.id, l.title_ar, coalesce(l.periods,1), coalesce(l.kind,'lesson')
        into v_lid, v_ltitle, v_lper, v_lkind
        from v2.curriculum_units u
        join v2.curriculum_lessons l on l.unit_id=u.id
       where u.grade=p_grade and u.term_no = p_term
         and (u.subject_ar = btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')))
         and not exists (select 1 from v2.lesson_plan_items i9
                           join v2.lesson_plans p9 on p9.id=i9.plan_id
                          where p9.school_id=p_school and p9.grade=p_grade
                            and p9.owner_person=v_owner
                            and p9.subject_ar=btrim(p_subject) and p9.term_no <> p_term
                            and i9.lesson_id=l.id and i9.week_no is not null)
         and not exists (select 1 from v2.lesson_plan_items i
                          where i.plan_id=v_plan and i.lesson_id=l.id
                            and (i.week_no is not null or i.merged_into is not null))
       order by u.ord nulls last, u.unit_no nulls last, l.ord nulls last, l.lesson_no nulls last
       limit 1;
      exit when v_lid is null;

      v_ord := v_ord + 1;
      insert into v2.lesson_plan_items (plan_id, lesson_id, week_no, ord, periods, state)
      values (v_plan, v_lid, w.week_no, v_ord, v_lper, 'planned')
      on conflict (plan_id, lesson_id) do update
        set week_no = excluded.week_no, ord = excluded.ord, periods = excluded.periods;

      v_placed := v_placed + 1;
      v_cap := v_cap - v_lper;
      v_wk_items := concat_ws(' · ', v_wk_items,
        case when v_lkind = 'lesson' then v_ltitle else '['||v_ltitle||']' end);
    end loop;

    if v_wk_items is not null then
      v_preview := v_preview || jsonb_build_object('week_no', w.week_no,
        'from_h', w.from_h, 'to_h', w.to_h, 'cap', w.cap, 'lessons', v_wk_items);
    end if;
  end loop;

  update v2.lesson_plan_items gi set week_no = h.week_no
    from v2.lesson_plan_items h
   where gi.plan_id=v_plan and gi.merged_into is not null
     and h.plan_id=v_plan and h.lesson_id=gi.merged_into;

  select count(*) into v_unplaced
    from v2.curriculum_units u
    join v2.curriculum_lessons l on l.unit_id=u.id
    left join v2.lesson_plan_items i on i.plan_id=v_plan and i.lesson_id=l.id
   where u.grade=p_grade and u.term_no = p_term
     and (u.subject_ar = btrim(p_subject) or u.subject_ar = any(coalesce(v_mapped,'{}')))
     and not exists (select 1 from v2.lesson_plan_items i9
                       join v2.lesson_plans p9 on p9.id=i9.plan_id
                      where p9.school_id=p_school and p9.grade=p_grade
                        and p9.owner_person=v_owner
                        and p9.subject_ar=btrim(p_subject) and p9.term_no <> p_term
                        and i9.lesson_id=l.id and i9.week_no is not null)
     and (i.id is null or i.week_no is null);

  v_slack := v_cap_term - v_per_total;

  update v2.lesson_plans
     set note_ar = case when v_unplaced > 0
          then 'نقصٌ: '||v_unplaced||' بندًا لم يجد أسبوعًا — والحاجةُ '||v_per_total
               ||' حصّةً والسعةُ '||v_cap_term||' في '||v_weeks||' أسبوعًا'
          else null end
   where id = v_plan;

  return jsonb_build_object('ok',true,'plan',v_plan,'build_no',coalesce(v_build,0)+1,
    'owner',v_owner,'owner_ar',v_owner_ar,'sections',v_secs,
    'weeks',v_weeks,'last_week',v_last_wk,'exam_week',v_exam_wk,'exam_from_h',v_exam_from,
    'items',v_need,'periods_need',v_per_total,'capacity',v_cap_term,'slack',v_slack,
    'placed',v_placed,'unplaced',v_unplaced,'weekly_slots',v_slots_wk,
    'finishes_before_exam',(v_unplaced = 0),
    'preview',v_preview,
    'summary_ar','حُسب توزيعُ «'||btrim(p_subject)||'» للصفّ '||p_grade||' · الفصلُ '||p_term
      ||' · للمعلّم '||v_owner_ar||' و'
      ||v2.ar_count(v_secs,'فصلٍ واحد','فصلين','فصولٍ','فصلًا')||' — '
      ||v2.ar_count(v_need,'بندٌ واحد','بندان','بنودٍ','بندًا')||' على '
      ||v2.ar_count(v_weeks,'أسبوعٍ واحد','أسبوعين','أسابيع','أسبوعًا')
      ||' · وينتهي المنهجُ في الأسبوع '||coalesce(v_last_wk::text,'؟')
      ||case when v_exam_wk is not null
             then ' · وأسبوعُ الاختبار '||v_exam_wk||' لا درسَ فيه' else '' end
      ||case when v_unplaced > 0
             then ' · 🔴 و'||v2.ar_count(v_unplaced,'بندٌ واحدٌ لم يجد أسبوعًا','بندان لم يجدا أسبوعًا',
                      'بنودٍ لم تجد أسبوعًا','بندًا لم يجد أسبوعًا')
             else ' · ولا نقصَ' end,
    'note_ar','مقترحٌ يُعرض ولا يُثبَّت — راجعه وعدِّله ثمّ أعلن أنّك أعدَدتَه. '
      ||'والتوزيعُ لك في مادّتك وصفّك، ويغطّي فصولَك كلَّها، والإنجازُ يُرصد لكلّ فصلٍ على حدة. '
      ||'وسعةُ الأسبوع من حصص المادّة في جدولك بعد خصم الإجازات. '
      ||'وأسبوعُ اختبارِ نهاية الفصل للاختبارات وحدَها — لا يُوضع فيه درسٌ ولا بندٌ، '
      ||'وينتهي المنهجُ في الأسبوع الذي قبله. '
      ||'والبنودُ بين قوسين [ ] ليست دروسًا تُدرَّس — اختبارٌ أو مراجعةٌ أو تهيئة، وتأخذ حصّتَها. '
      ||'والفسحةُ هي سعةُ الفصل ناقصَ ما يحتاجه المنهج: '||v_slack||' حصّة.');
end $function$
;
