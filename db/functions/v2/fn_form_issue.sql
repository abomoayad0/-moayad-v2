-- v2.fn_form_issue(p_form smallint, p_student uuid, p_record uuid, p_task uuid, p_data jsonb, p_by uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ea98a8fe9db2c5f066b5aaf6e0778bcc
CREATE OR REPLACE FUNCTION v2.fn_form_issue(p_form smallint, p_student uuid, p_record uuid, p_task uuid, p_data jsonb DEFAULT '{}'::jsonb, p_by uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_doc jsonb; v_data jsonb; v_sc uuid; v_entry uuid; v_cur record;
  v_miss text[] := array[]::text[]; r record; v_sent int := 0; v_final boolean;
begin
  select e.school_id into v_sc from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if v_sc is null then
    return jsonb_build_object('ok',false,'why','الطالب لا قيد فعّال له');
  end if;

  -- قيدٌ قائمٌ لهذي المهمّة؟ فلا يُكرَّر
  select * into v_cur from v2.form_entries
   where task_id = p_task and form_no = p_form and status <> 'void'
   order by created_at desc limit 1;

  v_doc  := v2.fn_form(p_form, p_student, p_record);
  v_data := v2.fn_form_auto(p_form, v_doc) || coalesce(p_data,'{}'::jsonb);

  -- ما يطلبه النموذجُ ولم يُملأ
  for r in select * from v2.form_schema
            where form_no=p_form and required and input<>'auto' loop
    if btrim(coalesce(v_data->>r.key,'')) = '' then
      v_miss := array_append(v_miss, r.label_ar);
    end if;
  end loop;
  v_final := array_length(v_miss,1) is null;

  if v_cur.id is null then
    insert into v2.form_entries(school_id, form_no, student_id, record_id, task_id,
        data, status, filled_by, filled_role, finalized_at, is_test)
    values (v_sc, p_form, p_student, p_record, p_task, v_data,
        case when v_final then 'final' else 'draft' end,
        p_by, 'إدارة المدرسة',
        case when v_final then now() end,
        coalesce((select test_mode from v2.schools where id=v_sc),false))
    returning id into v_entry;
  else
    v_entry := v_cur.id;
    if v_cur.status = 'draft' and v_final then
      update v2.form_entries
         set data=v_data, status='final', finalized_at=now(), updated_at=now()
       where id=v_entry;
    elsif v_cur.status = 'draft' then
      update v2.form_entries set data=v_data, updated_at=now() where id=v_entry;
    end if;
  end if;

  if v_final then
    v_sent := coalesce(v2.fn_form_deliver(v_entry),0);
  end if;

  return jsonb_build_object(
    'ok', v_final and v_sent > 0,
    'entry', v_entry,
    'form_no', p_form,
    'status', case when v_final then 'final' else 'draft' end,
    'delivered', v_sent,
    'missing', case when array_length(v_miss,1) is null then '[]'::jsonb
                    else to_jsonb(v_miss) end,
    'why', case
      when array_length(v_miss,1) is not null
        then 'أُنشئ مسودّةً — ويلزمه: '||array_to_string(v_miss,' · ')
      when v_sent = 0
        then 'اعتُمد ولم يُسلَّم — لا جهةَ تسلُّمٍ مسجّلةٌ للطالب'
      else null end);
end
$function$
;
