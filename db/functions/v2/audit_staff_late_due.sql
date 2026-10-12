-- v2.audit_staff_late_due()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 15d4491fd4853a10f00e97f1f4bd2572
CREATE OR REPLACE FUNCTION v2.audit_staff_late_due()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  select v2.fn_display_name(pe.full_name)||' — '||sc.name_ar,
         case when t.deduct_days_due > t.deduct_days_done
              then 'تأخّرُه '||t.hours_txt||' في عام '||z.fy||' فيجب أمرُ حسمٍ بمقدار '||
                   v2.ar_count(t.deduct_days_due - t.deduct_days_done,'يومٍ واحد','يومين','أيّامٍ','يومًا')
                   ||' ولم يُعدّ'
              when t.deduct_days_done > t.deduct_days_due
              then 'أُعدّ له حسمُ '||v2.ar_count(t.deduct_days_done,'يومٍ واحد','يومين','أيّامٍ','يومًا')
                   ||' في عام '||z.fy||' والواجبُ الآن '||
                   case when t.deduct_days_due = 0 then 'لا شيء' else v2.ar_count(t.deduct_days_due,'يومٌ واحد','يومان','أيّامٍ','يومًا') end
                   ||' — فقُبل عذرٌ بعد الإعداد، ويُراجَع الأمرُ الزائد'
              else 'تأخّرُه '||t.hours_txt||' في عام '||z.fy||' فيجب التنبيهُ ولم يُعدّ' end,
         case when t.deduct_days_done > t.deduct_days_due then 'انتبه' else 'خلل' end
    from (select distinct sl.school_id, sl.person_id, sl.fiscal_year fy
            from v2.staff_lateness sl where sl.voided_at is null) z
    join v2.schools sc on sc.id = z.school_id
    join v2.people pe on pe.id = z.person_id
    cross join lateral v2.staff_late_tally(z.school_id, z.person_id, z.fy) t
   where (t.notice_due and t.notice_n = 0)
      or (t.deduct_days_due <> t.deduct_days_done)
   order by 1
$function$
;
