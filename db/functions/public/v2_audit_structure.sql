-- public.v2_audit_structure()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 59b98fc1ce64a948c705c1f7fdb7a859
CREATE OR REPLACE FUNCTION public.v2_audit_structure()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r jsonb; n_bad int; n_warn int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'قراءةَ جرد البنية');
  select coalesce(jsonb_agg(jsonb_build_object(
      'door', x."باب", 'check', x."الفحص", 'expected', x."المتوقع",
      'actual', x."الواقع", 'verdict', x."الحكم", 'detail', x."التفصيل")), '[]'::jsonb),
    count(*) filter (where x."الحكم"='خلل'), count(*) filter (where x."الحكم"='انتبه')
    into r, n_bad, n_warn from v2.fn_audit() x;
  return jsonb_build_object('rows',r,'bad',n_bad,'warn',n_warn,
    'summary_ar','جردُ البنية — '||v2.ar_count(n_bad,'خللٌ واحد','خللان','خللٍ','خللًا')
      ||' و'||v2.ar_count(n_warn,'تنبيهٌ واحد','تنبيهان','تنبيهاتٍ','تنبيهًا'),
    'note_ar','قراءةٌ محضةٌ لا تكتب حرفًا — تفحص البياناتَ واللوائحَ والحرّاس.');
end $function$
;
