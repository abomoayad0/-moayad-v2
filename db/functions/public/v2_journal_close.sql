-- public.v2_journal_close(p_id uuid, p_state text, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 9e38af91692acfc22a22bfb5ea6ec48e
CREATE OR REPLACE FUNCTION public.v2_journal_close(p_id uuid, p_state text, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_t text;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'إقفالَ بندٍ في سجلّ البناء');
  if btrim(coalesce(p_state,'')) not in ('done','dropped','active') then
    raise exception 'الحالُ المقبول: done أُنجزت · dropped أُلغيت · active تُعاد قائمة';
  end if;
  if btrim(coalesce(p_why,'')) = '' then
    raise exception 'السببُ مطلوبٌ — ولا يُقفل بندٌ بلا سبب';
  end if;
  select title_ar into v_t from v2.build_journal where id=p_id;
  if v_t is null then raise exception 'لا بندَ بهذا الرقم'; end if;

  update v2.build_journal
     set state = btrim(p_state), closed_ar = btrim(p_why),
         closed_at = case when btrim(p_state)='active' then null else now() end
   where id = p_id;

  return jsonb_build_object('ok',true,
    'summary_ar','صار «'||v_t||'» '||case btrim(p_state) when 'done' then 'مُنجزًا'
      when 'dropped' then 'مُلغًى' else 'قائمًا' end,
    'note_ar','ولا يُحذف بندٌ من السجلّ — يُقفل بسببه ويبقى.');
end $function$
;
