-- v2.fn_advice_deliver(p_record uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 735be32819e5daa3395eee82463df6aa
CREATE OR REPLACE FUNCTION v2.fn_advice_deliver(p_record uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; v_ev uuid; n_g int := 0; v_stu boolean := false; st text; msg text;
begin
  select br.id, br.school_id, br.student_id, br.occurred_on, br.advice_ar, br.is_test,
         cp.text_ar as ptext, br.occurrence_no
    into r
    from v2.behavior_records br
    join v2.conduct_problems cp on cp.id = br.problem_id
   where br.id = p_record;
  if r.id is null or r.advice_ar is null then return null; end if;

  -- 🔑 لا يُرسل مرّتين · فالمحرّكُ قد يُعاد نداؤه
  if exists (select 1 from v2.events e
              where e.ref_table='behavior_records' and e.ref_id=p_record
                and e.kind='ladder_step' and e.title_ar like 'نصيحةٌ لك%') then
    return jsonb_build_object('ok',true,'already',true);
  end if;

  insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,
                        ref_table,ref_id,needs_action,action_ar,visible_to,is_test)
  values (r.school_id,'ladder_step',coalesce(r.occurred_on,current_date),r.student_id,
          'نصيحةٌ لك — '||r.ptext, r.advice_ar,
          'behavior_records', p_record, false, null, 'all', coalesce(r.is_test,false))
  returning id into v_ev;

  -- إلى صفحة الطالب إن كانت مفعَّلة
  select coalesce(s.portal_active,false) into v_stu from v2.students s where s.id=r.student_id;
  if v_stu then
    insert into v2.event_deliveries(event_id,channel,to_role,status,sent_at)
    values (v_ev,'student_portal','student','sent',now());
  end if;

  -- وإلى صفحة وليّ أمره — فمن لا صفحةَ له لا تُحجب عنه النصيحة
  insert into v2.event_deliveries(event_id,channel,to_guardian,status,sent_at)
  select v_ev,'guardian_portal',g.id,'sent',now()
    from v2.guardians g
   where g.student_id=r.student_id and coalesce(g.portal_active,false);
  n_g := coalesce((select count(*) from v2.event_deliveries d
                    where d.event_id=v_ev and d.channel='guardian_portal'),0);

  if v_stu then st := 'أُرسلت إلى صفحة الطالب'; else st := 'لا صفحةَ للطالب — فأُرسلت إلى وليّ أمره'; end if;
  msg := st || case when n_g>0 then ' · وإلى '||v2.ar_count(n_g,'وليٍّ واحد','وليَّين','أولياء','وليًّا') else '' end;

  return jsonb_build_object('ok',true,'event',v_ev,'to_student',v_stu,
    'to_guardians',n_g,'summary_ar',msg);
exception when others then
  -- الإرسالُ لا يُسقط الرصد — ولكنّه يُكتب في سجلّ الأخطاء ولا يُكتم
  perform v2.fn_log_error(sqlerrm,'fn_advice_deliver','السلوك','إيصالُ النصيحة إلى صفحة الطالب',
                          p_record::text,null);
  return jsonb_build_object('ok',false,'why',sqlerrm);
end $function$
;
