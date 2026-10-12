-- public.v2_absence_refer_counselor(p_case uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f8c49f2e0b032496eab9a1d58cf71176
CREATE OR REPLACE FUNCTION public.v2_absence_refer_counselor(p_case uuid, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare ac record; cid uuid; nm text; me uuid;
begin
  me := v2.current_person();
  select * into ac from v2.absence_cases where id = p_case;
  if ac.id is null then raise exception 'لا حالةَ غيابٍ بهذا المُعرّف'; end if;
  perform v2.assert_my_school(ac.school_id,'إحالةَ حالة الغياب إلى الموجّه');
  perform v2.assert_role(array['principal','deputy','deputy_students','deputy_school',
      'deputy_school_students','admin_assistant_students','counselor'],
      'إحالةَ حالة الغياب إلى الموجّه');

  select v2.fn_display_name(full_name) into nm from v2.students where id = ac.student_id;

  select cc.id into cid from v2.counsel_cases cc
   where cc.student_id = ac.student_id and cc.closed_on is null
   order by cc.opened_on desc limit 1;
  if cid is not null then
    return jsonb_build_object('case', cid, 'already', true,
      'said_ar', format('لـ%s حالةٌ مفتوحةٌ عند الموجّه من قبل — ولا تُفتح له حالتان', coalesce(nm,'الطالب')));
  end if;

  insert into v2.counsel_cases(school_id, student_id, year_id, term_no, source_ar,
      opened_on, opened_by, observed, is_test)
  values (ac.school_id, ac.student_id, ac.year_id, ac.term_no,
      'الغياب — أُحيل من حالةِ غيابٍ موقوفٍ تصعيدُها',
      current_date, me,
      nullif(btrim(coalesce(p_note,'')),''), coalesce(ac.is_test,false))
  returning id into cid;

  insert into v2.events(school_id, kind, on_date, student_id, title_ar, body_ar,
      ref_table, ref_id, visible_to, is_test)
  values (ac.school_id, 'case_study', current_date, ac.student_id,
      'أُحيل الطالبُ إلى الموجّه الطلابيّ — من حالة غياب',
      'حالةُ غيابٍ موقوفٌ تصعيدُها ('||v2.ar_num(ac.days_count)||' يومًا) أُحيلت للرعاية. '||
      coalesce('وسببُ الإحالة: '||nullif(btrim(coalesce(p_note,'')),''),'بلا سببٍ مكتوب'),
      'counsel_cases', cid, 'counselor_only', coalesce(ac.is_test,false));

  return jsonb_build_object('case', cid, 'already', false,
    'said_ar', format('أُحيل %s إلى الموجّه الطلابيّ — والوقفُ حمايةٌ لا إهمال', coalesce(nm,'الطالب')));
end $function$
;
