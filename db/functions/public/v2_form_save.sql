-- public.v2_form_save(p_form smallint, p_data jsonb, p_rows jsonb, p_student uuid, p_ref uuid, p_task uuid, p_entry uuid, p_final boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ca8eb218eb22faff219656d910da5615
CREATE OR REPLACE FUNCTION public.v2_form_save(p_form smallint, p_data jsonb, p_rows jsonb DEFAULT '[]'::jsonb, p_student uuid DEFAULT NULL::uuid, p_ref uuid DEFAULT NULL::uuid, p_task uuid DEFAULT NULL::uuid, p_entry uuid DEFAULT NULL::uuid, p_final boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare sc uuid; v uuid; cur text; p_d jsonb; miss text[] := array[]::text[]; r record; sent int := 0;
  st text; m text; d text; h text; c text;
begin
  if v2.my_role() not in ('counselor','deputy_students','deputy','principal','admin_assistant',
      'admin_assistant_students','subject_teacher','sped_teacher','gifted_teacher') then
    raise exception 'صفتك «%» لا تملك تعبئة النماذج الرسمية', v2.role_ar(v2.my_role()); end if;
  p_d := v2.fn_form_derive(p_form, v2.fn_form_strip(p_form, p_data), case when p_student is null then '{}'::jsonb else v2.fn_form_core(p_form,p_student,p_ref) end);
  if p_student is not null then perform v2.assert_my_student(p_student,'حفظ نموذج');
    select e2.school_id into sc from v2.enrolments e2 where e2.student_id=p_student and e2.status='active' limit 1;
  else sc := (select school_id from v2.session_role where user_id=auth.uid()); end if;
  if sc is null then raise exception 'لا مدرسة محدّدة'; end if;

  if p_entry is not null then
    select status into cur from v2.form_entries where id=p_entry;
    if cur is null then raise exception 'النموذج غير موجود'; end if;
    if cur='void' then raise exception 'النموذج مُلغًى'; end if;
    if cur='final' then raise exception 'النموذج معتمد ولا يُعدَّل — ويُلغى بسبب مكتوب ثم يُعاد'; end if;
  end if;

  if p_final then
    for r in select * from v2.form_schema where form_no=p_form and required and input<>'auto' loop
      if btrim(coalesce(p_d->>r.key,'')) = '' then miss := array_append(miss, r.label_ar); end if;
    end loop;
    if array_length(miss,1) is not null then
      raise exception 'لا يُعتمد النموذج بلا: %', array_to_string(miss,' · '); end if;
  end if;

  if p_entry is not null then
    update v2.form_entries set data=p_d, rows_data=p_rows, updated_at=now(),
      status = case when p_final then 'final' else 'draft' end,
      finalized_at = case when p_final then now() end
     where id=p_entry returning id into v;
  else
    insert into v2.form_entries(school_id,form_no,student_id,record_id,task_id,data,rows_data,
      status,filled_by,filled_role,finalized_at)
    values (sc,p_form,p_student,p_ref,p_task,p_d,p_rows,
      case when p_final then 'final' else 'draft' end,
      v2.current_person(), coalesce(v2.role_ar(v2.my_role()),'—'),
      case when p_final then now() end)
    returning id into v;
  end if;
  if p_final then sent := v2.fn_form_deliver(v); end if;
  return jsonb_build_object('entry_id',v,'status',case when p_final then 'final' else 'draft' end,
    'delivered', sent,
    'goes_to_ar', (select to_jsonb(goes_to_ar) from v2.official_forms where form_no=p_form));
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_form_save','النماذج','حفظ نموذج',
    jsonb_build_object('form',p_form,'student',p_student,'final',p_final),
    st,d,h,c,'bridge', case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
