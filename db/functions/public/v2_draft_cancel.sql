-- public.v2_draft_cancel(p_draft uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5228276d03b251b8f0568a371418bb33
CREATE OR REPLACE FUNCTION public.v2_draft_cancel(p_draft uuid, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
begin
  perform v2.assert_role(array['principal','deputy_academic','deputy'],'إلغاءَ مقترح');
  update v2.timetable_drafts set state='ملغًى',
     note_ar = coalesce(note_ar,'')||' · أُلغي: '||coalesce(btrim(p_why),'بلا سبب')
   where id=p_draft and state='مقترح' and v2.my_school(school_id);
  if not found then raise exception 'المقترحُ غيرُ موجودٍ أو لم يعد مقترحًا'; end if;
  return jsonb_build_object('ok',true);
end $function$
;
