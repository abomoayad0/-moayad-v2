-- public.v2_loyalty_of_section(p_section uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b3616e0c7d0b5c26e58fe0a2e7c45cc7
CREATE OR REPLACE FUNCTION public.v2_loyalty_of_section(p_section uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; r jsonb;
begin
  select school_id into sc from v2.class_sections where id = p_section;
  if sc is null then raise exception 'لا قسمَ بهذا المُعرّف'; end if;
  perform v2.assert_my_school(sc, 'قراءةَ أرصدة الفصل');
  select coalesce(jsonb_agg(jsonb_build_object(
          'student_id', t.id, 'name', v2.fn_display_name(t.full_name),
          'balance', v2.loyalty_balance(sc, t.id),
          'balance_ar', 'رصيدُه '||v2.ar_count(v2.loyalty_balance(sc, t.id),
              'نقطةٌ واحدة','نقطتان','نقاط','نقطة'))
        order by v2.fn_display_name(t.full_name)), '[]'::jsonb) into r
    from v2.students t
    join v2.enrolments e on e.student_id = t.id and e.ended_on is null
    join v2.class_sections cs on cs.school_id = e.school_id
         and cs.grade = e.grade and cs.section = e.section
    where cs.id = p_section;
  return jsonb_build_object('rows', r, 'count', jsonb_array_length(r),
    'note_ar','الأرصدةُ تُعرض بأسماء الطلّاب لا بترتيبِ الأكثر — فلا يُرتَّب الطلّابُ بعضُهم على بعض');
end $function$
;
