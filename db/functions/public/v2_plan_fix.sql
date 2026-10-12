-- public.v2_plan_fix(p_plan uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 96a5e829e82ced66aa4fe23596aae110
CREATE OR REPLACE FUNCTION public.v2_plan_fix(p_plan uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare
  g record; v_unplaced int; v_need int; v_cap int; v_rep uuid; v_mapped text[];
  v_pairs jsonb := '[]'::jsonb; v_free jsonb := '[]'::jsonb; v_owner uuid;
  v_merged int; v_short int;
begin
  select * into g from v2.plan_guard(p_plan,'قراءةَ مخارج النقص');
  select owner_person into v_owner from v2.lesson_plans where id=p_plan;

  select count(*) into v_unplaced from v2.lesson_plan_items
   where plan_id=p_plan and week_no is null;
  select count(*) into v_merged from v2.lesson_plan_items
   where plan_id=p_plan and merged_into is not null;

  select array_agg(m.curriculum_subject_ar) into v_mapped
    from v2.curriculum_subject_map m where m.plan_subject_ar = g.subject_ar;

  select coalesce(sum(coalesce(l.periods,1)),0) into v_need
    from v2.curriculum_units u join v2.curriculum_lessons l on l.unit_id=u.id
   where u.grade=g.grade and u.term_no=g.term_no
     and (u.subject_ar=g.subject_ar or u.subject_ar = any(coalesce(v_mapped,'{}')));

  select t.section_id into v_rep
    from v2.timetable t join v2.class_sections c on c.id=t.section_id
   where t.school_id=g.school_id and c.grade=g.grade
     and t.subject_ar=g.subject_ar and t.slot_kind='teaching'
   group by t.section_id order by count(*) desc limit 1;

  select coalesce(sum(c.cap),0) into v_cap
    from v2.school_weeks(g.school_id) x
    cross join lateral (select (select count(*) from v2.timetable t
        join v2.calendar_days d on d.week_id=x.week_id and d.day_kind='study'
             and extract(dow from d.on_g)::int = t.weekday
       where t.school_id=g.school_id and t.section_id=v_rep
         and t.subject_ar=g.subject_ar and t.slot_kind='teaching') as cap) c
   where x.term_no=g.term_no and not x.is_exam
     and x.week_no < coalesce((select min(y.week_no) from v2.school_weeks(g.school_id) y
                                where y.term_no=g.term_no and y.is_exam), 99);

  v_short := greatest(v_need - v_cap, 0);

  -- ① دمجاتٌ مقترحةٌ بقدر النقص: داخلَ الوحدة · درسٌ مع درس · حصّةً لكلٍّ · متجاورانِ
  if v_short > 0 then
    with cand as (
      select i.lesson_id, l.title_ar, l.unit_id, i.ord, i.periods,
             coalesce(i.kind_override,l.kind,'lesson') kind,
             lead(i.lesson_id) over (partition by l.unit_id order by i.ord) nx_id,
             lead(l.title_ar)  over (partition by l.unit_id order by i.ord) nx_title,
             lead(i.periods)   over (partition by l.unit_id order by i.ord) nx_per,
             lead(coalesce(i.kind_override,l.kind,'lesson')) over (partition by l.unit_id order by i.ord) nx_kind,
             u.title_ar unit_title
        from v2.lesson_plan_items i
        join v2.curriculum_lessons l on l.id=i.lesson_id
        join v2.curriculum_units u on u.id=l.unit_id
       where i.plan_id=p_plan and i.merged_into is null and i.state='planned'
    )
    select coalesce(jsonb_agg(jsonb_build_object(
             'guest', c.nx_id, 'guest_title', c.nx_title,
             'host', c.lesson_id, 'host_title', c.title_ar,
             'unit_ar', c.unit_title,
             'why_ar','درسانِ متجاوران في وحدةٍ واحدة، حصّةٌ لكلٍّ منهما')
           ),'[]'::jsonb) into v_pairs
      from (select * from cand
             where nx_id is not null and kind='lesson' and nx_kind='lesson'
               and coalesce(periods,1)=1 and coalesce(nx_per,1)=1
             limit greatest(v_short,0)) c;
  end if;

  -- ② حصصُ الانتظار الممكنةُ للتعويض — عرضٌ لا اعتماد
  if v_short > 0 and v_owner is not null then
    select coalesce(jsonb_agg(jsonb_build_object(
             'weekday', t.weekday, 'weekday_ar', t.weekday_ar, 'period_no', t.period_no)
             order by t.weekday, t.period_no),'[]'::jsonb) into v_free
      from v2.timetable t
     where t.school_id=g.school_id and t.person_id=v_owner and t.slot_kind <> 'teaching'
     limit 6;
  end if;

  return jsonb_build_object(
    'plan',p_plan,'grade',g.grade,'subject_ar',g.subject_ar,'term_no',g.term_no,
    'periods_need',v_need,'capacity',v_cap,'short',v_short,
    'unplaced',v_unplaced,'merged_now',v_merged,
    'merge_suggestions',v_pairs,
    'free_slots',v_free,
    'escalate_ar', case when v_short > 0 then
      'مادّةُ «'||g.subject_ar||'» للصفّ '||g.grade||' · الفصلُ '||g.term_no
      ||': المنهجُ يحتاج '||v_need||' حصّةً والنصابُ يتيح '||v_cap
      ||' — فالنقصُ '||v_short||' حصّة. والنصابُ والمنهجُ وحدُّ الفصلين كلُّها وزاريّةٌ '
      ||'لا تملك المدرسةُ تعديلَها، وترحيلُ الدروس بين الفصلين ممنوعٌ نظامًا. '
      ||'ويُرفع هذا البندُ لإدارة التعليم كما هو.' else null end,
    'summary_ar', case when v_short = 0
      then '✅ لا نقصَ — النصابُ يسع منهجَ هذا الفصل'
      else '🔴 نقصُ '||v2.ar_count(v_short,'حصّةٍ واحدة','حصّتين','حصص','حصّة')
           ||' · ومخارجُه ثلاثةٌ بترتيبها: دمجُ '
           ||v2.ar_count(jsonb_array_length(v_pairs),'درسٍ واحد','درسين','دروس','درسًا')
           ||' · ثمّ حصصٌ تعويضيّةٌ من انتظارك (عرضٌ لا إلزام) · ثمّ توثيقُ النقص للوكيل' end,
    'note_ar','الدمجُ أوّلًا فهو الأقرب — درسانِ في حصّةٍ واحدةٍ بإقرارك، والاثنان يبقيان في السجلّ. '
      ||'ثمّ الحصصُ التعويضيّةُ من حصص انتظارك: عرضٌ لا يُعتمد إلّا بضغطةٍ منك، ولا يُكرَّر عليك إن رددتَه. '
      ||'وإن بقي نقصٌ فلا يُحمَّل عليك — يُوثَّق للوكيل ويُرفع لإدارة التعليم، '
      ||'فالنصابُ والمنهجُ وحدُّ الفصلين وزاريّةٌ لا تُعدّلها المدرسة.');
end $function$
;
