-- public.v2_calendar_entry_remove(p_entry uuid, p_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bb0618a6ea98a93a5b61d619e5112fe6
CREATE OR REPLACE FUNCTION public.v2_calendar_entry_remove(p_entry uuid, p_reason text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_school uuid; v_title text; v_gone timestamptz;
begin
  select e.school_id, e.title, e.removed_at into v_school, v_title, v_gone
    from v2.calendar_entries e where e.id=p_entry;
  if v_school is null then raise exception 'لا بندَ بهذا الرقم في التقويم'; end if;
  if v_gone is not null then
    raise exception 'هذا البندُ مرفوعٌ من قبل — ولا يُرفع مرّتين';
  end if;
  perform v2.assert_my_school(v_school,'رفعَ بندٍ من التقويم');
  perform v2.assert_role(array['principal','deputy','deputy_school','deputy_academic',
    'deputy_school_students','admin_assistant','admin_assistant_students','info_registrar'],
    'رفعَ بندٍ من التقويم');
  if btrim(coalesce(p_reason,'')) = '' then
    raise exception 'سببُ الرفع مطلوبٌ — فالبندُ يبقى في السجلّ ومعه سببُ رفعه';
  end if;

  update v2.calendar_entries
     set removed_at = now(), removed_by = v2.current_person(), removed_why = btrim(p_reason)
   where id = p_entry;

  return jsonb_build_object('ok',true,
    'summary_ar','رُفع «'||coalesce(v_title,'البند')||'» من تقويم مدرستك',
    'note_ar','ولم يُحذف — يبقى في السجلّ ومعه سببُ رفعه ومن رفعه.');
end $function$
;
