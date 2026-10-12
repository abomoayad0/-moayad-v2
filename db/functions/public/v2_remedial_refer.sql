-- public.v2_remedial_refer(p_student uuid, p_to text, p_reason text, p_plan uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e06e2f2a1a221fce1d6f4e396e9afc0b
CREATE OR REPLACE FUNCTION public.v2_remedial_refer(p_student uuid, p_to text, p_reason text, p_plan uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; tm smallint; n int; v_id uuid; v_case uuid; v_min int; nm text; yr uuid;
begin
  perform v2.assert_my_student(p_student,'إحالةَ الطالب في الخطّة العلاجيّة');
  perform v2.assert_role(array['subject_teacher','sped_teacher','gifted_teacher',
    'deputy_academic','deputy','principal','counselor'],'إحالةَ الطالب في الخطّة العلاجيّة');
  if p_to not in ('counselor','deputy_students','principal') then
    raise exception 'جهاتُ الإحالة ثلاثٌ منصوصةٌ: الموجّهُ الطلابيّ · وكيلُ شؤون الطلّاب · مديرُ المدرسة — %',
      v2.cite_of('remedial.outputs'); end if;

  select e.school_id, e.year_id into sc, yr from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  tm := v2.fn_term_of(sc, current_date);
  v_min := v2.rule_n(sc,'reason_min_chars');
  if length(btrim(coalesce(p_reason,''))) < v_min then
    raise exception 'الإحالةُ لا تقع بلا سببٍ مكتوبٍ — وأقلُّه % حرفًا', v2.ar_num(v_min); end if;

  -- العتبةُ منصوصةٌ: مهارةٌ واحدةٌ من الحدّ الأدنى تكفي
  select count(*) into n
    from v2.skills s
    join lateral (select mm.level from v2.skill_marks mm
                   where mm.skill_id=s.id and mm.student_id=p_student and mm.term_no=tm
                     and mm.voided_at is null order by mm.on_date desc limit 1) m on true
    left join v2.skill_levels l on l.active and (l.school_id=sc or l.school_id is null)
      and v2.ar_bare(l.label_ar)=v2.ar_bare(m.level)
   where s.school_id=sc and s.kind='minimum' and s.voided_at is null and s.active
     and coalesce(l.is_mastered,false) = false;
  if n = 0 then
    raise exception 'لم يُرصد له إخلالٌ بمهارةٍ من مهارات الحدّ الأدنى — والنصُّ يُحيل من لم يتقن مهارةً أو أكثرَ منها (%)',
      v2.cite_of('remedial.min_skill_referral'); end if;

  if p_to = 'counselor' then
    select cc.id into v_case from v2.counsel_cases cc
     where cc.school_id=sc and cc.student_id=p_student and cc.term_no=tm
       and coalesce(cc.source_ar,'') like 'remedial.min_skill_referral%' limit 1;
    if v_case is null then
      insert into v2.counsel_cases(school_id,student_id,problem_id,year_id,term_no,
          source_ar,opened_on,opened_by,observed,is_test)
      values (sc,p_student,null,yr,tm,
          'remedial.min_skill_referral — '||v2.cite_of('remedial.min_skill_referral'),
          current_date, v2.current_person(),
          'لم يُتقن '||v2.ar_count(n,'مهارةً واحدة','مهارتين','مهاراتٍ','مهارةً')||' من مهارات الحدّ الأدنى · '
          ||btrim(p_reason),
          coalesce((select test_mode from v2.schools where id=sc),false))
      returning id into v_case;
    end if;
  end if;

  insert into v2.remedial_referrals(school_id,student_id,plan_id,term_no,to_whom,reason_ar,
      unmastered_min_n,case_id,by_person,is_test)
  values (sc,p_student,p_plan,tm,p_to,btrim(p_reason),n,v_case,v2.current_person(),
      coalesce((select test_mode from v2.schools where id=sc),false))
  returning id into v_id;

  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;
  return jsonb_build_object('ok',true,'referral',v_id,'case',v_case,'unmastered_min',n,
    'summary_ar','أُحيل '||coalesce(nm,'الطالب')||' إلى '||
      case p_to when 'counselor' then 'الموجّه الطلابيّ'
                when 'deputy_students' then 'وكيل شؤون الطلّاب' else 'مدير المدرسة' end
      ||' — لم يُتقن '||v2.ar_count(n,'مهارةً واحدة','مهارتين','مهاراتٍ','مهارةً')||' من الحدّ الأدنى',
    'note_ar',v2.cite_of('remedial.min_skill_referral'));
end $function$
;
