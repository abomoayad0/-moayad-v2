-- v2.outgoing_state_ar(p_status text, p_needs_reply boolean, p_cancel_reason text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 ad38ac9c4c1b0db6c00913a042091c62
CREATE OR REPLACE FUNCTION v2.outgoing_state_ar(p_status text, p_needs_reply boolean DEFAULT false, p_cancel_reason text DEFAULT NULL::text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select case p_status
    when 'draft'    then 'مسوّدةٌ عند معدّها — لم تُوقَّع ولم تخرج'
    when 'signed'   then 'مُوقَّعةٌ وبقي إخراجُها'
    when 'sent'     then case when p_needs_reply then 'خرجت وتنتظر جوابَ الجهة'
                              else 'خرجت ولا يُنتظر لها جواب' end
    when 'replied'  then 'وصل جوابُ الجهة'
    when 'closed'   then 'مُقفلة'
    when 'cancelled' then 'ملغاةٌ — والسببُ: '||coalesce(p_cancel_reason,'لم يُكتب')
    else p_status end;
$function$
;
