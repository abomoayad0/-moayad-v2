-- public.v2_late_refer(p_student uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 7e3890b8f4cfe24404034d13abf9440d
CREATE OR REPLACE FUNCTION public.v2_late_refer(p_student uuid, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; yr uuid; tm smallint; t record; cid uuid; nm text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_students','admin_assistant_students'],
    'إحالةَ المتأخّر إلى الموجّه الطلابيّ');
  perform v2.assert_my_student(p_student,'الإحالة للتأخّر');

  select e.school_id, e.year_id into sc, yr from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if sc is null then raise exception 'الطالب لا قيد فعّال له'; end if;
  tm := v2.fn_term_of(sc, current_date);

  select * into t from v2.late_tally(sc, p_student, tm);
  if not t.over then
    raise exception 'لم يتجاوز العتبةَ — تأخّرُه % بلا عذرٍ في هذا الفصل، والنصُّ يوجب الإحالةَ بتجاوز %',
      v2.ar_num(t.total_n), v2.ar_num(t.threshold);
  end if;

  cid := v2.late_referral_of(sc, p_student, tm);
  if cid is not null then
    raise exception 'أُحيل سلفًا في هذا الفصل بهذا السند — والحالةُ قائمةٌ عند الموجّه الطلابيّ';
  end if;

  insert into v2.counsel_cases(school_id,student_id,problem_id,year_id,term_no,
      source_ar,opened_on,opened_by,observed,is_test)
  values (sc,p_student,null,yr,tm,
      'attendance.late_referral — '||v2.cite_of('attendance.late_referral'),
      current_date, v2.current_person(),
      'تأخّرٌ متكرّرٌ بلا عذر: '||v2.ar_num(t.daily_n)||' يوميًّا و'||v2.ar_num(t.period_n)||
      ' بين الحصص · المجموع '||v2.ar_num(t.total_n)||' وآخرُها '||coalesce(t.last_on::text,'—')||
      coalesce(' · '||nullif(btrim(coalesce(p_note,'')),''),''),
      coalesce((select test_mode from v2.schools where id=sc),false))
  returning id into cid;

  select v2.fn_display_name(full_name) into nm from v2.students where id=p_student;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (sc,'case_study',current_date,p_student,
      'أُحيل إلى الموجّه الطلابيّ لتكرار التأخّر',
      'بواجبِ س-٦-ا-١ سياسة ٠١ ص١٧٩ — '||v2.cite_of('attendance.late_referral'),
      'counsel_cases',cid,'counselor_only',
      coalesce((select test_mode from v2.schools where id=sc),false));

  perform v2.log_action(sc,p_student,'late_referral','أُحيل المتأخّرُ إلى الموجّه الطلابيّ',
    'counsel_cases',cid, jsonb_build_object('total',t.total_n,'daily',t.daily_n,
      'period',t.period_n,'threshold',t.threshold));

  return jsonb_build_object('ok',true,'case',cid,'student',nm,
    'total_n',t.total_n,'daily_n',t.daily_n,'period_n',t.period_n,'threshold',t.threshold,
    'summary_ar','أُحيل '||coalesce(nm,'الطالب')||' إلى الموجّه الطلابيّ — تأخّرُه '
      ||v2.ar_count(t.total_n,'مرّةٌ واحدة','مرّتان','مرّاتٍ','مرّةً')||' بلا عذرٍ في هذا الفصل والعتبةُ '||v2.ar_num(t.threshold),
    'note_ar','وسندُ الإحالة مكتوبٌ في الحالة: س-٦-ا-١ سياسة ٠١ ص١٧٩ — فمن قرأها بعد عامٍ عرف لِمَ وقعت.');
end $function$
;
