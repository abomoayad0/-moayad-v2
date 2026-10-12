-- public.v2_reading_board(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0338c70c6026292875b8af0d6538a803
CREATE OR REPLACE FUNCTION public.v2_reading_board(p_school uuid, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; n_due int; n_ok int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','admin_assistant'],
    'قراءةَ لوحة استقطاع القراءة والكتابة');
  perform v2.assert_my_school(p_school,'قراءةَ لوحة استقطاع القراءة والكتابة');

  select coalesce(jsonb_agg(jsonb_build_object(
      'person', x.pid, 'name_ar', x.nm,
      'eligible', x.eligible_n, 'required', x.required_n,
      'done', x.done_n, 'skipped', x.skipped_n, 'missing', x.missing_n,
      'marks_n', x.marks_n,
      'state_ar', case when x.missing_n > 0 then '🔴 بقي '||v2.ar_num(x.missing_n)
                       when x.skipped_n > 0 then '🟠 نُفِّذ ما أمكن · وتعذّر '||v2.ar_num(x.skipped_n)
                       else '🟢 تمّ' end
    ) order by x.missing_n desc, x.nm), '[]'::jsonb),
    count(*) filter (where x.missing_n > 0), count(*) filter (where x.missing_n = 0)
    into r, n_due, n_ok
    from (select pe.id pid, v2.fn_display_name(pe.full_name) nm, d.*,
                 (select count(*) from v2.skill_marks sm
                   join v2.reading_sessions rs on rs.id = sm.session_id
                  where rs.person_id = pe.id and rs.on_date = p_date
                    and sm.voided_at is null and rs.voided_at is null) marks_n
            from v2.teaching_staff(p_school) z(person_id)
            join v2.people pe on pe.id = z.person_id
            cross join lateral v2.reading_due(p_school, pe.id, p_date) d
           where d.eligible_n > 0) x;

  return jsonb_build_object('ok',true,'on_date',p_date,'rows',r,
    'due', n_due, 'complete', n_ok,
    'summary_ar', case when jsonb_array_length(r)=0
      then 'لا معلّمَ عليه استقطاعٌ في هذا اليوم'
      else v2.ar_count(jsonb_array_length(r),'معلّمٌ واحدٌ عليه استقطاع','معلّمان عليهما استقطاع',
                       'معلّمين عليهم استقطاع','معلّمًا عليهم استقطاع')
           ||' · أتمّ '||v2.ar_num(n_ok)||' · وبقي على '||v2.ar_num(n_due) end,
    'note_ar','ومالكُ الإجراء الوكيلُ للشؤون التعليميّة، وهو من يراجع سجلَّ الدروس أسبوعيًّا ويعتمد — '
      ||v2.cite_of('skills.document_notes'));
end $function$
;
