-- v2.fn_send_prenotice(p_school uuid, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 0cda9ae5c31eb2c5b4731da1223fd8b1
CREATE OR REPLACE FUNCTION v2.fn_send_prenotice(p_school uuid, p_date date)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare st record; r record; g record; v_ev uuid; n int := 0;
begin
  select * into st from v2.day_settings where school_id=p_school;
  if not st.prenotice_on then return 0; end if;
  for r in select a.* from v2.attendance a
            where a.school_id=p_school and a.on_date=p_date
              and a.assembly_state='not_arrived' and a.arrived_at is null
              and a.day_status='provisional' loop
    insert into v2.events(school_id,kind,on_date,student_id,title_ar,body_ar,ref_table,ref_id)
    values (p_school,'absence_prenotice',p_date,r.student_id,'لم يحضر حتى الآن',
      'ابنكم لم يحضر إلى المدرسة حتى الآن. وهذا إشعار مبدئي لا حكم فيه، وإن حضر قبل إقفال اليوم أُلغي.',
      'attendance',r.id) returning id into v_ev;
    n := n + 1;
    for g in select id from v2.guardians where student_id=r.student_id loop
      insert into v2.event_deliveries(event_id,channel,to_guardian) values (v_ev,'guardian_portal',g.id);
      insert into v2.event_deliveries(event_id,channel,to_guardian) values (v_ev,'whatsapp',g.id);
    end loop;
  end loop;
  return n;
end $function$
;
