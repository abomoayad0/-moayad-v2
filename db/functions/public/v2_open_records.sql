-- public.v2_open_records(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ba67928677c3dc70349e58e1c7d67396
CREATE OR REPLACE FUNCTION public.v2_open_records(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r jsonb; n_total int; n_wait int; n_out int;
begin
  perform v2.assert_my_school(p_school,'قائمةَ الرصدات المفتوحة');
  perform v2.assert_role(array['deputy_students','deputy','principal','counselor',
      'admin_assistant','admin_assistant_students'],'قائمةَ الرصدات المفتوحة');

  with rec as (
    select br.id, br.student_id, br.occurred_on, br.step_no, br.occurrence_no,
           br.is_test, cp.text_ar problem_ar, cp.degree_no,
           (current_date - br.occurred_on) as age_days,
           (select count(*) from v2.behavior_tasks t
             where t.record_id = br.id and t.status = 'open') as open_n,
           exists (select 1 from v2.behavior_tasks t
                    where t.record_id = br.id and t.status = 'open'
                      and t.kind in ('committee','move_class')) as waits_committee,
           exists (select 1 from v2.behavior_tasks t
                    where t.record_id = br.id and t.status = 'open'
                      and t.kind in ('edu_decision','edu_report')) as waits_outgoing
      from v2.behavior_records br
      join v2.conduct_problems cp on cp.id = br.problem_id
     where br.school_id = p_school
       and br.status = 'open'
       and exists (select 1 from v2.behavior_tasks t
                    where t.record_id = br.id and t.status = 'open')
  ), oldest as (
    select rec.*, o.text_ar oldest_text, o.owner_role oldest_role, o.kind oldest_kind,
           v2.fn_display_name(pe.full_name) as oldest_person
      from rec
      left join lateral (
        select t.text_ar, t.owner_role, t.kind, t.owner_person
          from v2.behavior_tasks t
         where t.record_id = rec.id and t.status = 'open'
         order by t.created_at, t.ord
         limit 1) o on true
      left join v2.people pe on pe.id = o.owner_person
  )
  select coalesce(jsonb_agg(jsonb_build_object(
      'record', x.id,
      'student', x.student_id,
      'student_ar', (select v2.fn_display_name(s.full_name)
                       from v2.students s where s.id = x.student_id),
      'problem_ar', rtrim(btrim(x.problem_ar),'.'),
      'degree_ar', v2.degree_ar(x.degree_no),
      'step_ar', v2.ar_num(x.step_no),
      'occurrence_ar', v2.ord_ar(x.occurrence_no),
      'on_date', x.occurred_on,
      'age_days', x.age_days,
      'age_ar', case when x.age_days = 0 then 'اليومَ'
                     when x.age_days = 1 then 'منذ يوم'
                     when x.age_days = 2 then 'منذ يومين'
                     when x.age_days between 3 and 10 then 'منذ '||v2.ar_num(x.age_days)||' أيّام'
                     else 'منذ '||v2.ar_num(x.age_days)||' يومًا' end,
      'open_n', x.open_n,
      'open_ar', v2.ar_count(x.open_n,'بندٌ واحدٌ مفتوح','بندان مفتوحان',
                             'بنودٍ مفتوحة','بندًا مفتوحًا'),
      'oldest_item_ar', x.oldest_text,
      'oldest_owner_ar', coalesce(x.oldest_person, x.oldest_role),
      'waits_committee', x.waits_committee,
      'waits_outgoing', x.waits_outgoing,
      'why_ar', nullif(concat_ws(' · ',
          case when x.waits_committee
               then 'تنتظر قرارَ لجنة التوجيه الطلابيّ — ولا تقع إلّا به' end,
          case when x.waits_outgoing
               then 'وفيها بندٌ ينتظر سجلَّ الصادر — ولم يُبنَ بعد، ويُرفع اليومَ بالورق خارجَ النظام' end), ''),
      'state_ar', v2.record_state_ar('open'),
      'is_test', coalesce(x.is_test,false))
      order by x.age_days desc, x.occurred_on), '[]'::jsonb)
    into r
    from oldest x;

  n_total := jsonb_array_length(r);
  select count(*) filter (where (e->>'waits_committee')::boolean),
         count(*) filter (where (e->>'waits_outgoing')::boolean)
    into n_wait, n_out
    from jsonb_array_elements(r) e;

  return jsonb_build_object(
    'rows', r,
    'count', n_total,
    'waiting', n_wait,
    'waiting_outgoing', n_out,
    'note_ar', 'الأقدمُ أوّلًا · ولا مدّةَ يُنذَر بعدها: الدليلُ لم يحدَّ لأكثر البنود مدّةً، فالحكمُ لعينك',
    'summary_ar', case when n_total = 0 then 'لا رصدةَ فيها بندٌ مفتوح'
                       else 'عليك '||v2.ar_count(n_total,'رصدةٌ واحدةٌ فيها بندٌ مفتوح',
                                                 'رصدتان فيهما بندٌ مفتوح',
                                                 'رصداتٍ فيها بندٌ مفتوح',
                                                 'رصدةً فيها بندٌ مفتوح')||
                            case when n_wait > 0
                                 then ' · منها '||v2.ar_num(n_wait)||' تنتظر لجنةً' else '' end||
                            case when n_out > 0
                                 then ' · و'||v2.ar_num(n_out)||' تنتظر سجلَّ الصادر' else '' end end);
end
$function$
;
