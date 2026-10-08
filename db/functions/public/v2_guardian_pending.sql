-- public.v2_guardian_pending(p_student uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2100f7279413e2088f5e281b4544f362
CREATE OR REPLACE FUNCTION public.v2_guardian_pending(p_student uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_student_or_kin(p_student,'الدعوات المنتظرة');
  select coalesce(jsonb_agg(jsonb_build_object(
      'event',e.id,'kind',e.kind,'title',e.title_ar,'body',e.body_ar,
      'on_date',e.on_date,'action',e.action_ar,
      'replied',(x.id is not null),
      'reply',x.reply,'reply_note',x.note_ar,'suggested',x.suggested,
      'replied_at',x.replied_at)
      order by e.on_date desc),'[]'::jsonb)
  into r from v2.events e
  left join v2.guardian_replies x on x.event_id=e.id
  where e.student_id=p_student and e.needs_action and e.visible_to='all';
  return r;
end $function$
;
