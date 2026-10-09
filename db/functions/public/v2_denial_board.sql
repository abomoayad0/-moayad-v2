-- public.v2_denial_board(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2d2fc13d533f1c9b089bba17d788ddbc
CREATE OR REPLACE FUNCTION public.v2_denial_board(p_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v_year uuid; r jsonb; n_cross int; n_near int;
begin
  sc := coalesce(p_school, v2.acting_school());
  perform v2.assert_my_school(sc,'لوحةُ الحرمان');
  perform v2.assert_role(array['principal','deputy','deputy_students','admin_assistant',
      'admin_assistant_students','counselor'],'لوحةُ الحرمان');
  select id into v_year from v2.academic_years where school_id=sc and is_current limit 1;

  select coalesce(jsonb_agg(x order by (x->>'days')::int desc), '[]'::jsonb) into r from (
    select jsonb_build_object(
      'student', s.id, 'name', v2.fn_display_name(q."الطالب"),
      'grade', q."الصف", 'section', q."الفصل",
      'days', q."غياب_بلا_عذر",
      'limit', v2.denial_limit(q."أيام_دراسة_مقررة"),
      'year_days', q."أيام_دراسة_مقررة",
      'crossed', q."غياب_بلا_عذر" >= v2.denial_limit(q."أيام_دراسة_مقررة"),
      'warned', exists (select 1 from v2.denial_actions d where d.student_id=s.id
                         and d.year_id=v_year and d.kind='warning'),
      'decided', exists (select 1 from v2.denial_actions d where d.student_id=s.id
                          and d.year_id=v_year and d.kind='decision'
                          and not exists (select 1 from v2.denial_actions c
                                           where c.kind='cancel' and c.committee_entry=d.id)),
      'need_ar', case
        when q."غياب_بلا_عذر" < v2.denial_limit(q."أيام_دراسة_مقررة")
          then 'يقترب من الحدّ — والمتابعةُ أولى من القرار'
        when not exists (select 1 from v2.denial_actions d where d.student_id=s.id
                          and d.year_id=v_year and d.kind='warning')
          then 'تجاوز الحدَّ ولم يُنذَر وليُّه — والإنذارُ شرطٌ قبل القرار'
        when exists (select 1 from v2.denial_actions d where d.student_id=s.id
                      and d.year_id=v_year and d.kind='decision'
                      and not exists (select 1 from v2.denial_actions c
                                       where c.kind='cancel' and c.committee_entry=d.id))
          then 'صدر القرارُ في حقّه'
        else 'تجاوز الحدَّ وأُنذر وليُّه — فيُعرض على لجنة التوجيه ثمّ يُقرّر المدير' end) x
    from v2.fn_register_attendance(sc, v_year, null, null, null, null, null) q
    join v2.students s on s.student_no = q."رقم_الطالب"
    join v2.enrolments e on e.student_id = s.id and e.school_id = sc and e.status='active'
   where v2.denial_limit(q."أيام_دراسة_مقررة") is not null
     and q."غياب_بلا_عذر" >= greatest(v2.denial_limit(q."أيام_دراسة_مقررة") - 3, 1)
  ) t;

  select count(*) filter (where (x->>'crossed')::boolean),
         count(*) filter (where not (x->>'crossed')::boolean)
    into n_cross, n_near from jsonb_array_elements(r) x;

  return jsonb_build_object('rows', r, 'count', jsonb_array_length(r),
    'counts', jsonb_build_object('crossed',coalesce(n_cross,0),'near',coalesce(n_near,0)),
    'summary_ar', case when jsonb_array_length(r)=0 then 'لا طالبَ قريبًا من حدّ الحرمان'
      else btrim(concat_ws(' · ',
        case when coalesce(n_cross,0) > 0 then v2.ar_count(n_cross,'طالبٌ تجاوز الحدّ',
               'طالبان تجاوزا الحدّ','طلّابٍ تجاوزوا الحدّ','طالبًا تجاوز الحدّ') end,
        case when coalesce(n_near,0) > 0 then v2.ar_count(n_near,'طالبٌ يقترب من الحدّ',
               'طالبان يقتربان','طلّابٍ يقتربون','طالبًا يقترب') end)) end,
    'note_ar','القرارُ للمدير وحدَه · ولا يصدر إلّا بإنذارٍ موثَّقٍ لوليّ الأمر ومحضرِ لجنةٍ مُقفَل · '||
              'ويُلغى بسببٍ مكتوبٍ ولا يُحذف · والأرقامُ من سجلّ المواظبة نفسِه');
end $function$
;
