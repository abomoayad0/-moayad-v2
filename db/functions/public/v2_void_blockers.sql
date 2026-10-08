-- public.v2_void_blockers(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6f8ab95477eed6b7f3ebe3dcc3b9f2fd
CREATE OR REPLACE FUNCTION public.v2_void_blockers(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r record; rows jsonb;
begin
  select br.*, cp.text_ar ptext into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id = p_record;
  if r.id is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(r.student_id,'ما يمنع إلغاءَ الرصدة');

  select coalesce(jsonb_agg(jsonb_build_object(
      'record', x.id,
      'occurrence', x.occurrence_no,
      'occurrence_ar', v2.ord_ar(x.occurrence_no),
      'step_ar', v2.ar_num(x.step_no),
      'on_date', x.occurred_on,
      'state_ar', v2.record_state_ar(x.status),
      'label_ar', 'الواقعةُ '||v2.ord_ar(x.occurrence_no)||
                  ' ('||to_char(x.occurred_on,'YYYY-MM-DD')||')')
      order by x.occurrence_no desc), '[]'::jsonb)
    into rows
    from v2.behavior_records x
   where x.student_id = r.student_id and x.problem_id = r.problem_id
     and x.year_id = r.year_id and x.status <> 'voided'
     and x.occurrence_no > r.occurrence_no;

  return jsonb_build_object(
    'record', p_record,
    'problem_ar', rtrim(btrim(r.ptext),'.'),
    'occurrence_ar', v2.ord_ar(r.occurrence_no),
    'can_void', (jsonb_array_length(rows) = 0) and r.status <> 'voided',
    'already_void', (r.status = 'voided'),
    'blockers', rows,
    'why_ar', case
      when r.status = 'voided' then 'أُلغيت هذي الرصدةُ سلفًا'
      when jsonb_array_length(rows) > 0 then
        'لا تُلغى هذي قبل ما بعدها — فترقيمُ التكرارات وخطواتُ السلّم مبنيّةٌ عليها · أَلغِ من الآخر إلى الأوّل'
      else null end,
    'confirm_word', 'أُلغي');
end
$function$
;
