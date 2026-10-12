-- public.v2_rules_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 3ef73bd7731e377d64cf1696d08c5185
CREATE OR REPLACE FUNCTION public.v2_rules_board(p_school uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_my_school(p_school,'قراءةَ مرجع الأرقام');
  select coalesce(jsonb_agg(jsonb_build_object(
      'key', d.key, 'label_ar', d.label_ar,
      'value', coalesce(s.value_n, d.value_n),
      'unit_ar', d.unit_ar,
      'default_value', d.value_n,
      'from_ar', case when s.id is not null then 'قرارُ مدرستك' else 'الافتراضُ العامّ' end,
      'min', d.min_n, 'max', d.max_n,
      'source_kind', d.source_kind,
      'source_kind_ar', case d.source_kind
          when 'dalil' then 'منصوصٌ في الدليل'
          when 'school' then 'قرارُ مدرسة'
          else 'اجتهادُ بناء' end,
      'source_ar', coalesce(d.source_ar,'—'),
      'why_ar', d.why_ar,
      'editable', d.editable,
      'set_at', s.set_at,
      'set_by_ar', coalesce((select v2.fn_display_name(pe.full_name) from v2.people pe where pe.id=s.set_by),'—')
    ) order by d.source_kind, d.key), '[]'::jsonb) into r
    from v2.rule_numbers d
    left join v2.rule_numbers s on s.key = d.key and s.school_id = p_school
   where d.school_id is null;

  return jsonb_build_object('ok',true,'rows',r,'count',jsonb_array_length(r),
    'note_ar','ما كان منصوصًا في الدليل لا يُغيَّر من هنا · وما كان قرارَ مدرسةٍ أو اجتهادَ بناءٍ يُغيَّر بسببٍ يبقى مكتوبًا باسم من غيّره.');
end $function$
;
