-- public.v2_phrases_for(p_form smallint, p_field text, p_record uuid, p_task uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9d2ae186c86138c7c32a7d93d8d13395
CREATE OR REPLACE FUNCTION public.v2_phrases_for(p_form smallint, p_field text, p_record uuid DEFAULT NULL::uuid, p_task uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; f record; src record; r record; v_prob int;
        computed jsonb := '[]'::jsonb; phrases jsonb; mine jsonb; v_kind text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_academic',
      'deputy_school','deputy_academic_school','deputy_school_students',
      'admin_assistant','admin_assistant_students','counselor','subject_teacher'],
      'مكتبةُ العبارات');
  sc := v2.acting_school();

  select * into f from v2.form_schema where form_no=p_form and key=p_field;
  if f.key is null then raise exception 'لا حقلَ بهذا المفتاح في هذا النموذج'; end if;
  select * into src from v2.form_field_source where form_no=p_form and field_key=p_field;

  -- مشكلةُ الرصدة إن كانت
  if p_record is not null then
    select problem_id into v_prob from v2.behavior_records where id=p_record;
  end if;

  -- ══ ما يحسبه النظامُ ويقترحه جاهزًا ══
  if src.compute_kind = 'problem_text' and p_record is not null then
    select jsonb_build_array(jsonb_build_object('text',
             cp.text_ar||' — وقعت '||coalesce(v2.fn_to_hijri(br.occurred_on)||' هـ','')||
             coalesce(' في '||nullif(br.incident_place_ar,''),'')||
             ' · والمرّةُ '||v2.ord_ar(br.occurrence_no),
           'why','من الرصدة نفسِها — فلا يُكتب وصفُ المشكلة من الذاكرة'))
      into computed
      from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
     where br.id=p_record;

  elsif src.compute_kind = 'prior_tasks' then
    if p_record is not null then
      select jsonb_build_array(jsonb_build_object('text',
               string_agg(t.text_ar, ' · ' order by t.ord),
             'why','ما تمَّ فعلًا من بنود السلّم — بشواهده في النظام'))
        into computed from v2.behavior_tasks t
       where t.record_id=p_record and t.status='done';
    elsif p_task is not null then
      select jsonb_build_array(jsonb_build_object('text',
               string_agg(t.text_ar, ' · ' order by t.ord),
             'why','ما تمَّ فعلًا من بنود سلّم المواظبة'))
        into computed from v2.absence_tasks t
       where t.case_id = (select case_id from v2.absence_tasks where id=p_task)
         and t.status='done';
    end if;

  elsif src.compute_kind = 'case_students' and p_record is not null then
    select jsonb_build_array(jsonb_build_object('text',
             s.full_name||coalesce(' · والمتعرّض: '||v.full_name,''),
           'why','من الرصدة — الفاعلُ ومن تعرّض له'))
      into computed
      from v2.behavior_records br
      join v2.students s on s.id=br.student_id
      left join v2.students v on v.id=br.victim_student_id
     where br.id=p_record;

  elsif src.compute_kind = 'committee_members' then
    select jsonb_build_array(jsonb_build_object('text',
             string_agg(pe.full_name||' ('||
               case cm.seat_role when 'chair' then 'رئيسًا'
                                 when 'rapporteur' then 'مقرّرًا' else 'عضوًا' end||')',
               ' · ' order by case cm.seat_role when 'chair' then 1
                                                 when 'rapporteur' then 2 else 3 end, pe.full_name),
           'why','أعضاءُ لجنة التوجيه المسجَّلون لهذي السنة — وتُحذف منهم من غاب'))
      into computed
      from v2.committee_members cm
      join v2.people pe on pe.id=cm.person_id
     where cm.committee_key='guidance' and cm.school_id=sc
       and (cm.ended_on is null or cm.ended_on >= current_date)
       and (cm.year_id is null or cm.year_id in
             (select y.id from v2.academic_years y where y.school_id=sc and y.is_current));

  elsif src.compute_kind = 'academic_year' then
    select jsonb_build_array(jsonb_build_object('text', y.name,
           'why','العامُ الدراسيُّ الجاري من تقويم مدرستك'))
      into computed from v2.academic_years y
     where y.school_id=sc and y.is_current limit 1;
  end if;

  computed := coalesce(computed,'[]'::jsonb);

  -- ══ المكتبةُ بثلاث طبقات ══
  if src.bank_key is null then
    phrases := '[]'::jsonb;
  else
    select coalesce(jsonb_agg(x order by x->>'layer', (x->>'used')::int desc, x->>'ord'), '[]'::jsonb)
      into phrases
      from (
        select jsonb_build_object(
                 'id', b.id, 'text', b.text_ar, 'ord', lpad(coalesce(b.ord,99)::text,3,'0'),
                 'layer', case when b.problem_id is not null and b.problem_id = v_prob then '1'
                               when b.school_id = sc then '2'
                               else '3' end,
                 'why', case when b.problem_id is not null and b.problem_id = v_prob
                               then 'خاصٌّ بهذي المشكلة بعينها'
                             when b.school_id = sc then 'من مكتبة مدرستك'
                             else 'عامٌّ من الدليل والممارسة' end,
                 'used', (select count(*) from v2.phrase_use u
                           where u.phrase_id=b.id and u.school_id=sc),
                 'source', b.source_ar) x
          from v2.phrase_bank b
         where b.active and b.bank_key = src.bank_key
           and (b.school_id is null or b.school_id = sc)
           and (b.problem_id is null or b.problem_id = v_prob)
      ) q;
  end if;

  select coalesce(jsonb_agg(jsonb_build_object('id',b.id,'text',b.text_ar) order by b.id), '[]'::jsonb)
    into mine from v2.phrase_bank b
   where b.active and b.bank_key = src.bank_key and b.school_id = sc;

  return jsonb_build_object(
    'form', p_form, 'field', p_field,
    'label_ar', f.label_ar, 'hint_ar', f.hint_ar, 'required', f.required,
    'source_ar', case when src.by_hand then 'بيدك وحدَك'
                      when src.compute_kind is not null and src.bank_key is not null
                        then 'يحسبه النظامُ ومعه مكتبة'
                      when src.compute_kind is not null then 'يحسبه النظام'
                      when src.bank_key is not null then 'مكتبة'
                      else 'بلا منبعٍ بعد' end,
    'note_ar', coalesce(src.note_ar,'—'),
    'computed', computed,
    'phrases', phrases,
    'mine', mine,
    'counts', jsonb_build_object('computed', jsonb_array_length(computed),
                                 'phrases', jsonb_array_length(phrases)),
    'summary_ar', case
      when src.by_hand then 'هذا الحقلُ بيدك — ولا يُقترح لك فيه شيءٌ بطبيعته'
      when jsonb_array_length(computed) > 0 and jsonb_array_length(coalesce(phrases,'[]'::jsonb)) > 0
        then 'يقترح النظامُ نصًّا جاهزًا، ومعه '||
             v2.ar_count(jsonb_array_length(phrases),'عبارةٌ في المكتبة','عبارتان','عبارات','عبارةً')
      when jsonb_array_length(computed) > 0 then 'يقترح النظامُ نصًّا جاهزًا من بياناته'
      when jsonb_array_length(coalesce(phrases,'[]'::jsonb)) > 0
        then v2.ar_count(jsonb_array_length(phrases),'عبارةٌ واحدةٌ في المكتبة',
               'عبارتان في المكتبة','عباراتٍ في المكتبة','عبارةً في المكتبة')
      else 'لا منبعَ لهذا الحقل بعد — وهذا نقصٌ مُعلَنٌ لا سكوت' end,
    'how_ar','تُدرج العبارةُ ولا تُقفل — تبقى قابلةً للتعديل، ويُجمع أكثرُ من عبارةٍ بفواصل');
end $function$
;
