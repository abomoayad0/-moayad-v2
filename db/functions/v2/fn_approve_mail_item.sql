-- v2.fn_approve_mail_item(p_item uuid, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2494dca4d20d13a8486b2e59aac645c6
CREATE OR REPLACE FUNCTION v2.fn_approve_mail_item(p_item uuid, p_by uuid DEFAULT NULL::uuid)
 RETURNS TABLE("متابعات" integer, "إقرارات" integer, "معلّق" integer)
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
declare it record; m record; t record; p record; n_f int:=0; n_a int:=0; n_p int:=0; v_ev uuid;
begin
  select * into it from v2.mail_items where id=p_item;
  if it.id is null then raise exception 'البند غير موجود'; end if;
  if it.approved then raise exception 'البند مُقَرّ سلفاً'; end if;
  if not exists (select 1 from v2.mail_targets g where g.item_id=p_item) then
    raise exception 'لا يُقَرّ بند بلا جهة موجَّه إليها'; end if;
  select * into m from v2.incoming_mail where id=it.mail_id;

  update v2.mail_items set approved=true, approved_by=p_by, approved_at=now() where id=p_item;

  for t in select * from v2.mail_targets where item_id=p_item loop
    if t.target_kind in ('person','persons') then
      insert into v2.mail_followups(item_id,person_id,due_on,status)
      values (p_item,t.person_id,it.ends_on,
        case when it.kind='إبلاغ بالعلم' then 'not_required' else 'open' end);
      n_f := n_f + 1;
      insert into v2.mail_acknowledgements(mail_id,item_id,person_id) values (m.id,p_item,t.person_id);
      n_a := n_a + 1;
    elsif t.target_kind in ('role','assignment') then
      insert into v2.mail_followups(item_id,role_ar,due_on,status)
      values (p_item, coalesce(t.role_ar,t.assignment_ar), it.ends_on,
        case when it.kind='إبلاغ بالعلم' then 'not_required' else 'open' end);
      n_f := n_f + 1;
      update v2.mail_targets set pending_expansion=true,
        pending_note='لم يُفرَد إلى أشخاص: المناصب والتكاليف غير مسجّلة في v2 بعد. يُفرَد متى سُجّل المنسوبون.'
       where id=t.id;
      n_p := n_p + 1;
    elsif t.target_kind='all_staff' then
      if exists (select 1 from v2.people limit 1) then
        for p in select id from v2.people loop
          insert into v2.mail_acknowledgements(mail_id,item_id,person_id) values (m.id,p_item,p.id);
          n_a := n_a + 1;
        end loop;
      else
        update v2.mail_targets set pending_expansion=true,
          pending_note='لم يُفرَد: لا منسوبين مسجّلين في v2 بعد.' where id=t.id;
        n_p := n_p + 1;
      end if;
    elsif t.target_kind='guardians' then
      for p in select g.id from v2.guardians g join v2.students s on s.id=g.student_id
               where s.school_id=m.school_id loop
        insert into v2.mail_acknowledgements(mail_id,item_id,guardian_id) values (m.id,p_item,p.id);
        n_a := n_a + 1;
      end loop;
    elsif t.target_kind='students' then
      for p in select id from v2.students where school_id=m.school_id loop
        insert into v2.mail_acknowledgements(mail_id,item_id,student_id) values (m.id,p_item,p.id);
        n_a := n_a + 1;
      end loop;
    end if;
  end loop;

  update v2.incoming_mail set status='directed', directed_by=coalesce(directed_by,p_by),
         directed_at=coalesce(directed_at,now()) where id=m.id and status='new';

  insert into v2.events(school_id,kind,on_date,title_ar,body_ar,ref_table,ref_id,needs_action,action_ar)
  values (m.school_id,'other',current_date,'تكليف من وارد: '||m.subject_ar,
    it.text_ar||coalesce(' · ينتهي في '||it.ends_on,''),'mail_items',p_item,
    it.kind='تكليف','التنفيذ ثم الإقرار بالاطلاع') returning id into v_ev;
  insert into v2.event_deliveries(event_id,channel,to_role) values (v_ev,'staff_inbox','المكلَّفون');

  return query select n_f, n_a, n_p;
end $function$
;
