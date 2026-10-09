-- public.v2_form_open(p_form smallint, p_student uuid, p_ref uuid, p_task uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 4d3b52a02f599a6da29e54db2ec75a10
CREATE OR REPLACE FUNCTION public.v2_form_open(p_form smallint, p_student uuid DEFAULT NULL::uuid, p_ref uuid DEFAULT NULL::uuid, p_task uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare doc jsonb; e record; st text; m text; d text; h text; c text; v_prob int;
begin
  if p_student is not null then perform v2.assert_my_student(p_student,'فتح نموذج'); end if;
  doc := case when p_student is null then '{}'::jsonb else v2.fn_form(p_form,p_student,p_ref) end;
  if p_ref is not null then
    select problem_id into v_prob from v2.behavior_records where id = p_ref;
  end if;

  select * into e from v2.form_entries fe
   where fe.form_no=p_form and fe.status<>'void'
     and (p_task is not null and fe.task_id=p_task
       or p_task is null and fe.student_id is not distinct from p_student
          and fe.record_id is not distinct from p_ref)
   order by fe.created_at desc limit 1;

  return jsonb_build_object(
   'form_no', p_form,
   'title_ar', (select title_ar from v2.official_forms where form_no=p_form),
   'source', (select source_doc||' · '||source_page from v2.official_forms where form_no=p_form),
   'signers', (select to_jsonb(signers) from v2.official_forms where form_no=p_form),
   'goes_to', (select to_jsonb(goes_to) from v2.official_forms where form_no=p_form),
   'goes_to_ar', (select to_jsonb(goes_to_ar) from v2.official_forms where form_no=p_form),
   'final_label_ar', (select final_label_ar from v2.official_forms where form_no=p_form),
   'final_done_ar', (select final_done_ar from v2.official_forms where form_no=p_form),
   'can_void', v2.can_do(array['deputy_students','deputy','principal']),
   'can_edit', v2.my_role() in ('counselor','deputy_students','deputy','principal',
       'admin_assistant','admin_assistant_students','subject_teacher','sped_teacher','gifted_teacher'),
   'schema', coalesce((select jsonb_agg(jsonb_build_object('key',s.key,'label',s.label_ar,
       'input',s.input,'options',to_jsonb(s.options),'required',s.required,'hint',s.hint_ar,
       'filled_by_ar',s.filled_by_ar,'derived_from',s.derived_from,
       'source', case when fs.by_hand then 'by_hand'
                      when fs.compute_kind is not null and fs.bank_key is not null then 'both'
                      when fs.compute_kind is not null then 'computed'
                      when fs.bank_key is not null then 'library'
                      else 'none' end,
       'source_ar', case when fs.by_hand then 'بيدك وحدَك'
                         when fs.compute_kind is not null and fs.bank_key is not null
                           then 'يحسبه النظامُ ومعه مكتبة'
                         when fs.compute_kind is not null then 'يحسبه النظام'
                         when fs.bank_key is not null then 'مكتبة'
                         else null end,
       'bank_key', fs.bank_key,
       'phrases_n', case when fs.bank_key is null then 0 else
           (select count(*) from v2.phrase_bank b
             where b.active and b.bank_key = fs.bank_key
               and (b.school_id is null or b.school_id = v2.acting_school())
               and (b.problem_id is null or b.problem_id = v_prob)) end,
       'source_note_ar', fs.note_ar) order by s.ord)
     from v2.form_schema s
     left join v2.form_field_source fs on fs.form_no=s.form_no and fs.field_key=s.key
     where s.form_no=p_form),'[]'::jsonb),
   'row_schema', coalesce((select jsonb_agg(jsonb_build_object('key',r.key,'label',r.label_ar,
       'input',r.input,'options',to_jsonb(r.options)) order by r.ord)
     from v2.form_row_schema r where r.form_no=p_form),'[]'::jsonb),
   'auto', v2.fn_form_auto(p_form, doc) || jsonb_build_object(
     'guardian_reply', (select fi.reply from v2.form_inbox fi
       where fi.entry_id = e.id and fi.to_kind='guardian' and fi.reply is not null limit 1),
     'guardian_opinion', e.guardian_note),
   'awaiting_guardian', (select bool_or(fi.replied_at is null) from v2.form_inbox fi
       where fi.entry_id = e.id and fi.to_kind='guardian'),
   'auto_rows', v2.fn_form_rows(p_form, doc),
   'doc', doc,
   'entry', case when e.id is null then null else jsonb_build_object(
     'id', e.id, 'status', e.status, 'data', e.data, 'rows', e.rows_data,
     'filled_role', e.filled_role,
     'finalized_h', case when e.finalized_at is null then null
                    else v2.fn_to_hijri(e.finalized_at::date)||' هـ' end,
     'signatures', coalesce((select jsonb_agg(jsonb_build_object('signer',g.signer_ar,
         'signed',g.signed,'refused',g.refused,'reason',g.refuse_reason,
         'at_h', case when g.signed_at is null then null else v2.fn_to_hijri(g.signed_at::date)||' هـ' end))
       from v2.form_signatures g where g.entry_id=e.id),'[]'::jsonb)) end);
exception when others then
  get stacked diagnostics st=returned_sqlstate, m=message_text, d=pg_exception_detail,
    h=pg_exception_hint, c=pg_exception_context;
  perform v2.fn_log_error(m,'v2_form_open','النماذج','فتح نموذج',
    jsonb_build_object('form',p_form,'student',p_student,'ref',p_ref,'task',p_task),
    st,d,h,c,'bridge', case when st='P0001' then 'guard' else 'error' end);
  raise exception '%', m using errcode = st;
end $function$
;
