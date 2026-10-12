-- public.v2_form_entries(p_form smallint, p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f816ab64734b681dcd96b00b4cab8c86
CREATE OR REPLACE FUNCTION public.v2_form_entries(p_form smallint, p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_my_student(p_student, 'محاضرَ نماذج الطالب');
  return jsonb_build_object(
    'form_no', p_form,
    'title_ar', (select title_ar from v2.official_forms where form_no = p_form),
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object(
          'entry', fe.id,
          'status', fe.status,
          'final', fe.finalized_at is not null,
          'on_ar', v2.fn_to_hijri(fe.created_at::date),
          'linked_record', fe.record_id,
          'linked_task', fe.task_id,
          'linked_ar', case when fe.record_id is not null then 'مربوطٌ برصدة'
                            when fe.task_id is not null then 'مربوطٌ بمهمّة'
                            else 'غيرُ مربوط' end,
          'by_ar', (select v2.fn_display_name(p.full_name) from v2.people p where p.id=fe.filled_by),
          'by_role_ar', fe.filled_role)
        order by fe.created_at desc)
      from v2.form_entries fe
      where fe.form_no = p_form and fe.student_id = p_student and fe.status <> 'void'), '[]'::jsonb),
    'note_ar','تُعرض محاضرُ الطالب كلُّها في هذا النموذج — المربوطُ برصدةٍ والمربوطُ بمهمّةٍ وغيرُ المربوط · '||
              'فمحضرُ اللجنةِ المربوطُ برصدةٍ كان يسقط من الاختيار');
end $function$
;
