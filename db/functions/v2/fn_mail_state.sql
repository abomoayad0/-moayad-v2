-- v2.fn_mail_state(p_mail uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e887fd18ebda0760b920cc2e04e889b4
CREATE OR REPLACE FUNCTION v2.fn_mail_state(p_mail uuid)
 RETURNS TABLE("بنود" integer, "مُقَرّة" integer, "متابعات_مفتوحة" integer, "متأخرة" integer, "مطلوب_إقرارهم" integer, "أقرّوا" integer, "رفضوا" integer, "نسبة_الاطلاع" numeric)
 LANGUAGE sql
 STABLE
 SET search_path TO 'v2', 'public'
AS $function$
select
 (select count(*)::int from v2.mail_items i where i.mail_id=p_mail),
 (select count(*)::int from v2.mail_items i where i.mail_id=p_mail and i.approved),
 (select count(*)::int from v2.mail_followups f join v2.mail_items i on i.id=f.item_id
   where i.mail_id=p_mail and f.status in ('open','in_progress')),
 (select count(*)::int from v2.mail_followups f join v2.mail_items i on i.id=f.item_id
   where i.mail_id=p_mail and f.status in ('open','in_progress')
     and f.due_on is not null and f.due_on < current_date),
 (select count(*)::int from v2.mail_acknowledgements a where a.mail_id=p_mail),
 (select count(*)::int from v2.mail_acknowledgements a where a.mail_id=p_mail and a.signed),
 (select count(*)::int from v2.mail_acknowledgements a where a.mail_id=p_mail and a.refused),
 (select case when count(*)=0 then 0 else round(count(*) filter (where signed)*100.0/count(*),1) end
    from v2.mail_acknowledgements a where a.mail_id=p_mail);
$function$
;
