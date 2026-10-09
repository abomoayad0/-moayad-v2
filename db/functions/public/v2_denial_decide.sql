-- public.v2_denial_decide(p_student uuid, p_committee_entry uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6369d3fc7027251de688ba862eccb86a
CREATE OR REPLACE FUNCTION public.v2_denial_decide(p_student uuid, p_committee_entry uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v_year uuid; v_abs int; v_limit int; v_year_days int; v_pct numeric;
        v_warn record; v_entry record; v_id uuid; v_ev uuid; v_name text; v_test boolean;
begin
  perform v2.assert_role(array['principal'],'قرارَ الحرمان من الانتقال');
  perform v2.assert_my_student(p_student,'قرارَ الحرمان');
  select e.school_id, e.year_id into sc, v_year from v2.enrolments e
   where e.student_id=p_student and e.status='active' order by e.created_at desc limit 1;

  if exists (select 1 from v2.denial_actions d where d.student_id=p_student
              and d.year_id=v_year and d.kind='decision') then
    raise exception 'صدر قرارُ الحرمان في حقّ هذا الطالب هذي السنةَ سلفًا'; end if;
  if length(btrim(coalesce(p_note,''))) < 10 then
    raise exception 'قرارُ الحرمان لا يصدر بلا سببٍ مكتوبٍ يبقى في السجلّ باسمك'; end if;

  select "أيام_دراسة_مقررة", "غياب_بلا_عذر" into v_year_days, v_abs
    from v2.fn_register_attendance(sc, v_year, null, null, null, null, p_student) limit 1;
  select value_num into v_pct from v2.conduct_rules where key='attendance.denial_pct';
  v_limit := case when coalesce(v_year_days,0)=0 then null
                  else floor(v_year_days * v_pct / 100.0)::int + 1 end;

  if v_limit is null then raise exception 'لا يُعرف عددُ أيّام الدراسة — فلا يُحسب الحدّ'; end if;
  if coalesce(v_abs,0) < v_limit then
    raise exception '%', 'لم يبلغ الطالبُ حدَّ الحرمان — غيابُه بغير عذرٍ '||
      v2.ar_num(coalesce(v_abs,0))||' والحدُّ '||v2.ar_num(v_limit)||
      ' يومًا من أصل '||v2.ar_num(v_year_days)||' يومًا دراسيًّا'; end if;

  select * into v_warn from v2.denial_actions
   where student_id=p_student and year_id=v_year and kind='warning';
  if v_warn.id is null then
    raise exception '%', 'لم يُنذَر وليُّ الأمر قبل بلوغ الحدّ — '||
      'ولا يصدر قرارٌ قبل إنذارٍ موثَّق · وبابُه يُنادى عند الرصد، أو أنذِره الآن'; end if;

  if p_committee_entry is null then
    raise exception '%', 'قرارُ الحرمان لا يصدر إلّا بعد عرضِ الحالة على لجنة التوجيه الطلابيّ — '||
      'فأرفِق محضرَ اللجنة (نموذج ١٢)'; end if;
  select fe.* into v_entry from v2.form_entries fe where fe.id=p_committee_entry;
  if v_entry.id is null or v_entry.form_no <> 12 then
    raise exception 'المرفقُ ليس محضرَ لجنة التوجيه (نموذج ١٢)'; end if;
  if v_entry.status <> 'final' then
    raise exception 'محضرُ اللجنة لم يُقفل بعد — فأتمَّه أوّلًا'; end if;
  if v_entry.student_id is distinct from p_student then
    raise exception 'محضرُ اللجنة المرفقُ ليس في حقّ هذا الطالب'; end if;

  select s.full_name into v_name from v2.students s where s.id=p_student;
  v_test := coalesce((select test_mode from v2.schools where id=sc),false);

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
  values (sc,'absence_report',current_date,p_student,
      'قرارٌ بالحرمان من الانتقال',
      'صدر قرارُ مدير المدرسة بحرمان ابنكم '||coalesce(v2.fn_display_name(v_name),'')||
      ' من الانتقال لتجاوز غيابه بغير عذرٍ '||v2.ar_num(v_abs)||' يومًا، '||
      'وحدُّ الحرمان '||v2.ar_num(v_limit)||' يومًا من أصل '||v2.ar_num(v_year_days)||
      ' يومًا دراسيًّا · بعد عرض الحالة على لجنة التوجيه الطلابيّ. '||btrim(p_note),
      'denial_actions',null,'all',true,'أقرَّ بالاطّلاع', v_test)
  returning id into v_ev;

  insert into v2.denial_actions(school_id,student_id,year_id,kind,days_absent,limit_days,
      committee_entry,reason,by_person,event_id,is_test)
  values (sc,p_student,v_year,'decision',v_abs,v_limit,p_committee_entry,btrim(p_note),
      v2.current_person(),v_ev,v_test)
  returning id into v_id;

  update v2.events set ref_id=v_id where id=v_ev;
  perform v2.log_action(sc,p_student,'denial_decide','صدر قرارُ الحرمان من الانتقال',
    'denial_actions',v_id, jsonb_build_object('days',v_abs,'limit',v_limit));

  return jsonb_build_object('ok',true,'decision',v_id,'days',v_abs,'limit',v_limit,
    'citation_ar', (select 'م'||article_no||' · '||source_doc||' '||source_page
                      from v2.conduct_rules where key='attendance.denial_pct'),
    'note_ar','صدر القرارُ وسُلّم إلى بوّابة وليّ الأمر · ومحضرُ اللجنة مربوطٌ به · '||
              'ويُلغى بـ v2_denial_cancel بسببٍ مكتوبٍ ولا يُحذف');
end $function$
;
