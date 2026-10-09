-- public.v2_outgoing_enums()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6fd7a84db5ed97c6a121fda6e7c37576
CREATE OR REPLACE FUNCTION public.v2_outgoing_enums()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select jsonb_build_object(
    'kind', jsonb_build_array(
      jsonb_build_object('v','letter','ar','خطاب'),
      jsonb_build_object('v','report','ar','تقريرٌ أو محضر'),
      jsonb_build_object('v','decision','ar','قرار'),
      jsonb_build_object('v','referral','ar','إحالة'),
      jsonb_build_object('v','circular','ar','تعميم'),
      jsonb_build_object('v','reply','ar','ردٌّ على وارد')),
    'secrecy', jsonb_build_array(
      jsonb_build_object('v','عادي','ar','عادي'),
      jsonb_build_object('v','سري','ar','سري'),
      jsonb_build_object('v','سري للغاية','ar','سري للغاية')),
    'channel', jsonb_build_array(
      jsonb_build_object('v','نظام رسمي','ar','نظام رسمي · ويلزمه مرجعُ إحالة'),
      jsonb_build_object('v','بريد','ar','بريد'),
      jsonb_build_object('v','يد','ar','تسليمٌ باليد'),
      jsonb_build_object('v','ورق','ar','ورق')),
    'status', jsonb_build_array(
      jsonb_build_object('v','draft','ar',v2.outgoing_state_ar('draft')),
      jsonb_build_object('v','signed','ar',v2.outgoing_state_ar('signed')),
      jsonb_build_object('v','sent','ar',v2.outgoing_state_ar('sent',true)),
      jsonb_build_object('v','replied','ar',v2.outgoing_state_ar('replied')),
      jsonb_build_object('v','closed','ar',v2.outgoing_state_ar('closed')),
      jsonb_build_object('v','cancelled','ar','ملغاة')),
    'reply_days_default', (select min(outgoing_reply_days) from v2.conduct_school_rules),
    'note_ar','هذي قوائمُ القاعدة بألفاظها — ولا تُنسخ في الشاشة، فإن زدنا قناةً عرفتَها');
$function$
;
