-- public.v2_refer_committee(p_record uuid, p_task uuid, p_why text, p_ask text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 62cabad2eb542ee92aa39385a1d155b1
CREATE OR REPLACE FUNCTION public.v2_refer_committee(p_record uuid, p_task uuid, p_why text, p_ask text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; resp jsonb; nid uuid; cs record; cen record;
begin
  perform v2.assert_role(array['deputy_students','deputy','principal'],'الإحالةَ إلى اللجنة');
  select br.*, cp.text_ar ptext into r
    from v2.behavior_records br join v2.conduct_problems cp on cp.id=br.problem_id
   where br.id=p_record;
  if r.id is null then raise exception 'الرصدةُ غيرُ موجودة'; end if;
  perform v2.assert_my_student(r.student_id,'الإحالة إلى اللجنة');

  resp := public.v2_response_check(p_record);
  if not (resp->>'can_refer')::boolean then
    raise exception 'لا تُفتح الإحالةُ بعد — %. و%', resp->>'why',
      coalesce(resp->>'rule','عدمُ الاستجابة يُثبَت بما وقع بعد الخطّة'); end if;
  if btrim(coalesce(p_why,''))='' then raise exception 'اكتب سببَ الإحالة'; end if;
  if btrim(coalesce(p_ask,''))='' then raise exception 'اكتب المطلوبَ من اللجنة'; end if;

  select * into cs from v2.counsel_cases where student_id=r.student_id
   order by opened_on desc limit 1;
  select * into cen from v2.behavior_census where student_id=r.student_id and state='مكتمل'
   order by filed_at desc limit 1;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
      ref_table,ref_id,visible_to,needs_action,action_ar,is_test)
  values (r.school_id,'committee',current_date,r.student_id,
      'أُحيل الملفُّ إلى لجنة التوجيه',
      btrim(p_why)||' · المطلوب: '||btrim(p_ask),
      'behavior_records',r.id,'staff',true,'انظر الملفَّ في اجتماع اللجنة',
      coalesce((select test_mode from v2.schools where id=r.school_id),false))
  returning id into nid;

  if p_task is not null then
    update v2.behavior_tasks set status='done', done_at=now(), done_by=v2.current_person(),
      ev_on=current_date, ev_text='أُحيل الملفُّ إلى اللجنة — '||btrim(p_why)
     where id=p_task and status<>'done';
  end if;

  perform v2.log_action(r.school_id,r.student_id,'refer_committee',
    'أُحيل الملفُّ إلى اللجنة','behavior_records',r.id,
    jsonb_build_object('why',btrim(p_why)));
  return jsonb_build_object('ok',true,'event',nid,
    'file', jsonb_build_object(
      'student',(select v2.fn_display_name(s.full_name) from v2.students s where s.id=r.student_id),
      'problem', rtrim(btrim(r.ptext),'.'),
      'occurrences_ar', v2.ord_ar(r.occurrence_no),
      'latest_ar', (select v2.ord_ar(max(x.occurrence_no)) from v2.behavior_records x
          where x.student_id=r.student_id and x.problem_id=r.problem_id
            and x.status<>'voided'),
      'total_ar', (select v2.ar_num(count(*)) from v2.behavior_records x
          where x.student_id=r.student_id and x.problem_id=r.problem_id
            and x.status<>'voided'),
      'deducted_ar',(select v2.ar_num(coalesce(-sum(points),0)) from v2.behavior_ledger l
                      where l.student_id=r.student_id and l.kind='deduction'),
      'census', case when cen.id is null then 'لم يُكتب' else 'مرفقٌ معها' end,
      'case', case when cs.id is null then 'لا دراسةَ حالة' else 'مرفقةٌ معها' end,
      'response', resp),
    'note','أُحيل الملفُّ — وينظر فيه مقرّرُ اللجنة في أوّل اجتماع');
end $function$
;
