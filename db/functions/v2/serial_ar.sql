-- v2.serial_ar(n integer, p_kind text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 be61a8536a6d6f720bf9adebdafee169
CREATE OR REPLACE FUNCTION v2.serial_ar(n integer, p_kind text DEFAULT 'in'::text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
AS $function$
  select case
    when n is null then case when p_kind = 'out' then 'بلا رقمِ صادرٍ بعد — والرقمُ يُعطى بالتوقيع'
                             else 'بلا رقمِ واردٍ بعد' end
    else case when p_kind = 'out' then 'الصادرُ رقم ' else 'الواردُ رقم ' end || v2.ar_num(n)
  end;
$function$
;
