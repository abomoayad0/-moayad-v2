-- public.v2_draft_cancel(p_draft uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 bcbd1461bb0ff5b05523cb6503afa868
CREATE OR REPLACE FUNCTION public.v2_draft_cancel(p_draft uuid, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare d record;
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy'],'إلغاءَ مقترح');
  select * into d from v2.timetable_drafts where id=p_draft;
  if d.id is null then raise exception 'المقترحُ غيرُ موجود'; end if;
  if not v2.my_school(d.school_id) then raise exception 'ليست مدرستك'; end if;
  if d.state <> 'مقترح' then raise exception 'هذا المقترحُ % سلفًا', d.state; end if;
  if btrim(coalesce(p_why,''))='' then
    raise exception 'لا يُلغى مقترحٌ بلا سببٍ مكتوب'; end if;
  update v2.timetable_drafts set state='ملغًى',
     note_ar = coalesce(note_ar||' · ','')||'أُلغي: '||btrim(p_why)
   where id=p_draft;
  return jsonb_build_object('ok',true);
end $function$
;
