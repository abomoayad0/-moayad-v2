-- public.v2_skill_report_notify(p_report uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 826e288b787c4b81950351ea7a189b14
CREATE OR REPLACE FUNCTION public.v2_skill_report_notify(p_report uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; nm text; v_ev uuid; v_body text; v_max int; v_done int;
begin
  perform v2.assert_role(array['deputy_academic','deputy','principal','admin_assistant'],
    'إرسالَ إشعار التقويم لوليّ الأمر');
  select * into r from v2.skill_reports where id=p_report and voided_at is null;
  if r.id is null then raise exception 'لا تقريرَ بهذا المعرّف'; end if;
  perform v2.assert_my_school(r.school_id,'إرسالَ إشعار التقويم لوليّ الأمر');
  if r.approved_at is null then
    raise exception 'لا يُشعَر وليُّ الأمر قبل اعتماد الوكيل — ونصُّه: %',
      v2.cite_of('assess.approve_reports'); end if;
  if r.notified_at is not null then
    raise exception 'أُشعر وليُّ الأمر سلفًا في %', r.notified_at::date; end if;

  select v2.fn_display_name(full_name) into nm from v2.students where id=r.student_id;
  v_max := v2.rule_n(r.school_id,'assess_notices_per_term');

  v_body := 'إشعارُ التقويم المستمرّ — الدورةُ '||v2.ar_num(r.round_no)||' من '||v2.ar_num(v_max)
    ||' في الفصل '||v2.ar_num(r.term_no)||'. ابنُكم '||coalesce(nm,'')
    ||': أتقنَ '||v2.ar_count(r.mastered_n,'مهارةً واحدة','مهارتين','مهاراتٍ','مهارةً')
    ||case when r.unmastered_n > 0
        then '، ولم يُتقن '||v2.ar_count(r.unmastered_n,'مهارةً واحدة','مهارتين','مهاراتٍ','مهارةً')
        else '، ولا مهارةَ غيرَ متقنةٍ' end
    ||case when r.unmeasured_n > 0 then '، وبقي '||v2.ar_num(r.unmeasured_n)||' لم تُقَس بعد' else '' end
    ||case when r.tools_ar is not null then '. وأدواتُ التقويم: '||r.tools_ar else '' end
    ||case when r.weak then '. ويحتاج ابنُكم إلى متابعةٍ في المهارات غير المتقنة، وقد نُظر في حالته مع المعلّم الخبير.' else '.' end;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,is_test)
  values (r.school_id,'other',current_date,r.student_id,
      'إشعارُ التقويم المستمرّ', v_body,
      'skill_reports',p_report,'all',coalesce(r.is_test,false))
  returning id into v_ev;

  update v2.skill_reports set notified_at=now(), event_id=v_ev, state='notified' where id=p_report;

  select count(*) into v_done from v2.skill_reports
   where school_id=r.school_id and student_id=r.student_id and term_no=r.term_no
     and notified_at is not null and voided_at is null;

  return jsonb_build_object('ok',true,'report',p_report,'event',v_ev,
    'round',r.round_no,'of',v_max,'notified_in_term',v_done,
    'summary_ar','أُشعر وليُّ أمر '||coalesce(nm,'الطالب')||' — الدورةُ '||v2.ar_num(r.round_no)
      ||' من '||v2.ar_num(v_max)||' · وأُشعر في هذا الفصل '||v2.ar_num(v_done),
    'note_ar','ونصُّه: '||v2.cite_of('assess.guardian_twice')
      ||' · والإرسالُ الفعليُّ يجري بآلةِ الإخطار القائمة في النظام، وهذا الإشعارُ مقيَّدٌ في سجلّ الأحداث.');
end $function$
;
