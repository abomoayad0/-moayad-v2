-- public.v2_audit_board(p_check text, p_all boolean)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2bb247a19b73b74318be53ecf34d301f
CREATE OR REPLACE FUNCTION public.v2_audit_board(p_check text DEFAULT NULL::text, p_all boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'قراءةَ لوحة الجرد');
  select coalesce(jsonb_agg(jsonb_build_object(
      'finding', f.id, 'check', f.check_key, 'label_ar', c.label_ar,
      'object', f.object_ar, 'detail_ar', f.detail_ar, 'severity', f.severity,
      'first_h', v2.fn_to_hijri(f.first_seen::date)||' هـ',
      'last_h',  v2.fn_to_hijri(f.last_seen::date)||' هـ',
      'seen_n', f.seen_n,
      'state_ar', case when f.waived_at is not null then '⚪ أُسقط بسببٍ مكتوب'
                       when f.resolved_at is not null then '✅ أُصلح'
                       when f.seen_n > 1 and f.resolved_at is null then '🔴 مفتوحٌ ويتكرّر'
                       else '🔴 مفتوح' end,
      'waive_why', f.waive_why)
      order by case when f.resolved_at is null and f.waived_at is null then 0 else 1 end,
               f.severity, c.ord, f.object_ar), '[]'::jsonb) into r
    from v2.audit_findings f join v2.audit_checks c on c.key=f.check_key
   where (p_check is null or f.check_key = p_check)
     and (p_all or (f.resolved_at is null and f.waived_at is null));
  return jsonb_build_object('rows',r,'count',jsonb_array_length(r),
    'summary_ar', case when jsonb_array_length(r)=0 then 'لا خللَ مفتوحًا في هذا الكشّاف'
      else v2.ar_count(jsonb_array_length(r),'سطرٌ واحد','سطران','سطورٍ','سطرًا') end);
end $function$
;
