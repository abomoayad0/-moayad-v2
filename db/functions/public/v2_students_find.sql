-- public.v2_students_find(p_text text, p_in_grade smallint, p_in_section text, p_max integer, p_of_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9e1b179c8ae6dffa831d711d3b3c6b95
CREATE OR REPLACE FUNCTION public.v2_students_find(p_text text DEFAULT NULL::text, p_in_grade smallint DEFAULT NULL::smallint, p_in_section text DEFAULT NULL::text, p_max integer DEFAULT 60, p_of_school uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; r jsonb; n int; v_q text; v_scoped boolean := false; v_secs int := 0;
begin
  sc := coalesce(p_of_school, v2.acting_school());
  if sc is null then raise exception 'لم تُعرف مدرستُك — فاختر صفتَك أوّلًا'; end if;
  perform v2.assert_my_school(sc,'بحثَ الطلّاب');

  -- 🔑 إدارةُ المدرسة تبحث في المدرسة كلِّها · والمعلّمُ في طلّابه هو
  begin
    perform v2.assert_role(array['principal','deputy','deputy_students','deputy_academic',
        'deputy_school','deputy_school_students','admin_assistant','admin_assistant_students',
        'info_registrar','counselor'],'بحثَ الطلّاب');
  exception when others then
    perform v2.assert_role(array['subject_teacher'],'بحثَ الطلّاب');
    v_scoped := true;
  end;

  if v_scoped then
    select count(*) into v_secs from v2.my_taught_sections(sc);
    if v_secs = 0 then
      return jsonb_build_object('rows','[]'::jsonb,'count',0,'total',0,'more',false,
        'scoped', true, 'sections_n', 0,
        'summary_ar','لا فصلَ مُسندًا إليك في هذي المدرسة — فلا طالبَ في بحثك',
        'note_ar','بحثُك في طلّابك أنت · والإسنادُ يُقرأ من نصابك ومن جدولك. فإن كان ناقصًا فراجِع وكيلَ الشؤون التعليميّة.');
    end if;
  end if;

  v_q := nullif(btrim(coalesce(p_text,'')),'');

  select count(*) into n from v2.students s
   join v2.enrolments e on e.student_id=s.id and e.school_id=sc and e.status='active'
   where (p_in_grade is null or e.grade=p_in_grade)
     and (p_in_section is null or e.section=p_in_section)
     and (not v_scoped or exists (select 1 from v2.my_taught_sections(sc) ts
                                   where ts.grade=e.grade and ts.section=e.section))
     and (v_q is null or s.full_name ilike '%'||v_q||'%'
          or coalesce(s.student_no,'') like '%'||v_q||'%'
          or coalesce(s.national_id,'') like '%'||v_q||'%');

  select coalesce(jsonb_agg(x),'[]'::jsonb) into r from (
    select jsonb_build_object('student',s.id,'student_no',s.student_no,
             'name',v2.fn_display_name(s.full_name),'full_name',s.full_name,
             'grade',e.grade,'section',e.section,'stage',e.stage,
             'guardians',(select count(*) from v2.guardians g where g.student_id=s.id)) x
      from v2.students s
      join v2.enrolments e on e.student_id=s.id and e.school_id=sc and e.status='active'
     where (p_in_grade is null or e.grade=p_in_grade)
       and (p_in_section is null or e.section=p_in_section)
       and (not v_scoped or exists (select 1 from v2.my_taught_sections(sc) ts
                                     where ts.grade=e.grade and ts.section=e.section))
       and (v_q is null or s.full_name ilike '%'||v_q||'%'
            or coalesce(s.student_no,'') like '%'||v_q||'%'
            or coalesce(s.national_id,'') like '%'||v_q||'%')
     order by e.grade, e.section, s.full_name
     limit greatest(coalesce(p_max,60),1)) q;

  return jsonb_build_object('rows', r, 'count', jsonb_array_length(r), 'total', n,
    'more', n > jsonb_array_length(r),
    'scoped', v_scoped, 'sections_n', case when v_scoped then v_secs else null end,
    'summary_ar', case when n = 0 then
        case when v_q is null then 'لا طالبَ في هذا الكشف'
             else 'لا طالبَ يُطابق «'||v_q||'»' end
      else v2.ar_count(n,'طالبٌ واحد','طالبان','طلّاب','طالبًا')||
           case when n > jsonb_array_length(r)
                then ' · عُرض منهم '||v2.ar_num(jsonb_array_length(r))||' — فضيّق البحث'
                else '' end end,
    'note_ar', case when v_scoped
        then 'بحثُك في طلّابك أنت — '||v2.ar_count(v_secs,'فصلٌ واحدٌ مُسندٌ إليك','فصلان مُسندان إليك','فصولٍ مُسندةٍ إليك','فصلًا مُسندًا إليك')||' · ابحث بالاسم أو برقم الطالب'
        else 'ابحث بالاسم أو برقم الطالب أو بالهويّة — ولا يلزمك اختيارُ صفٍّ ولا فصل' end);
end $function$
;
