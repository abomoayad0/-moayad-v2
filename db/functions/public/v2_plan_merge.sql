-- public.v2_plan_merge(p_plan uuid, p_lesson uuid, p_into uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 66f46c68ad8134e0dbcb5d7532b3f728
CREATE OR REPLACE FUNCTION public.v2_plan_merge(p_plan uuid, p_lesson uuid, p_into uuid, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare g record;
  a_title text; a_per smallint; a_kind text; a_unit uuid; a_week smallint; a_state text; a_merged uuid;
  b_title text; b_per smallint; b_kind text; b_unit uuid; b_week smallint; b_merged uuid;
  v_host_guest int;
begin
  select * into g from v2.plan_guard(p_plan,'دمجَ درسين في حصّة');
  if p_lesson = p_into then raise exception 'لا يُدمج البندُ في نفسه'; end if;
  if btrim(coalesce(p_why,'')) = '' then
    raise exception 'سببُ الدمج مطلوبٌ — فالدمجُ ضرورةٌ لسدّ نقصٍ لا عادةٌ في التدريس';
  end if;

  select l.title_ar, i.periods, coalesce(i.kind_override,l.kind,'lesson'), l.unit_id,
         i.week_no, i.state, i.merged_into
    into a_title, a_per, a_kind, a_unit, a_week, a_state, a_merged
    from v2.lesson_plan_items i join v2.curriculum_lessons l on l.id=i.lesson_id
   where i.plan_id=p_plan and i.lesson_id=p_lesson;
  if a_title is null then raise exception 'البندُ المدموجُ ليس في هذي الخطّة'; end if;

  select l.title_ar, i.periods, coalesce(i.kind_override,l.kind,'lesson'), l.unit_id,
         i.week_no, i.merged_into
    into b_title, b_per, b_kind, b_unit, b_week, b_merged
    from v2.lesson_plan_items i join v2.curriculum_lessons l on l.id=i.lesson_id
   where i.plan_id=p_plan and i.lesson_id=p_into;
  if b_title is null then raise exception 'البندُ المضيفُ ليس في هذي الخطّة'; end if;

  -- 🛡 الحارسُ الأوّل: داخلَ الوحدة الواحدة
  if a_unit <> b_unit then
    raise exception 'لا يُدمج درسانِ من وحدتين مختلفتين — فهما موضوعان لا موضوع. «%» في وحدةٍ و«%» في أخرى',
      a_title, b_title;
  end if;
  -- 🛡 الثاني: لا اختبارَ ولا مراجعةَ ولا تهيئةَ في الدمج
  if a_kind <> 'lesson' or b_kind <> 'lesson' then
    raise exception 'لا يُدمج إلّا درسٌ مع درس — والاختبارُ والمراجعةُ والتهيئةُ بنودٌ لها طبيعتُها';
  end if;
  -- 🛡 الثالث: درسٌ بحصّةٍ واحدةٍ فقط
  if coalesce(a_per,1) > 1 or coalesce(b_per,1) > 1 then
    raise exception 'لا يُدمج درسٌ حصصُه أكثرُ من واحدة — «%» له % و«%» له %',
      a_title, a_per, b_title, b_per;
  end if;
  -- 🛡 الرابع: لا دمجَ على دمج
  if a_merged is not null then raise exception '«%» مدموجٌ من قبل — فافصله أوّلًا', a_title; end if;
  if b_merged is not null then raise exception '«%» مدموجٌ في غيره — فلا يكون مضيفًا', b_title; end if;
  select count(*) into v_host_guest from v2.lesson_plan_items
   where plan_id=p_plan and merged_into = p_lesson;
  if v_host_guest > 0 then raise exception '«%» مضيفٌ لبندٍ آخر — فلا يُدمج هو', a_title; end if;
  select count(*) into v_host_guest from v2.lesson_plan_items
   where plan_id=p_plan and merged_into = p_into;
  if v_host_guest > 0 then raise exception '«%» مضيفٌ لبندٍ آخرَ أصلًا — ولا يُجمع ثلاثةُ دروسٍ في حصّة', b_title; end if;
  if a_state <> 'planned' then
    raise exception '«%» رُصدت حالتُه — ولا يُدمج بندٌ أُنجز أو رُحّل أو فات', a_title; end if;

  update v2.lesson_plan_items
     set merged_into = p_into, week_no = b_week,
         merged_by = v2.current_person(), merged_at = now(), merge_why = btrim(p_why)
   where plan_id=p_plan and lesson_id=p_lesson;

  return jsonb_build_object('ok',true,'guest',p_lesson,'host',p_into,'week_no',b_week,
    'summary_ar','دُمج «'||a_title||'» مع «'||b_title||'» في حصّةٍ واحدةٍ — الأسبوعُ '||coalesce(b_week::text,'؟'),
    'note_ar','والاثنان باقيان في السجلّ، وتُحسب حصّةُ المضيف وحدَها، فتُوفَّر حصّةٌ للمنهج. '
      ||'وإقرارُك مُسجَّلٌ بسببه.');
end $function$
;
