-- v2.audit_reading_due()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 27146b61c57190f695077718a225a1b1
CREATE OR REPLACE FUNCTION v2.audit_reading_due()
 RETURNS TABLE(obj text, why_ar text, severity text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
  with lastday as (
    select sc.id school_id, sc.name_ar,
           (select max(dd)::date from generate_series(current_date - 14, current_date - 1, interval '1 day') dd
             where coalesce(v2.fn_day_kind(sc.id, dd::date),'') in ('study','exam')) d
      from v2.schools sc)
  select v2.fn_display_name(pe.full_name)||' — '||l.name_ar,
         'في '||l.d||' كان عليه '||v2.ar_count(dd.required_n,'حصّةٌ واحدة','حصّتان','حصصٍ','حصّةً')
           ||' من استقطاع القراءة والكتابة ولم يُسجّل منها '||v2.ar_num(dd.missing_n),
         'خلل'
    from lastday l
    join (select distinct t.school_id, t.person_id from v2.timetable t
           where t.slot_kind in ('teaching','activity')) z on z.school_id = l.school_id
    join v2.people pe on pe.id = z.person_id
    cross join lateral v2.reading_due(l.school_id, z.person_id, l.d) dd
   where l.d is not null and dd.required_n > 0 and dd.missing_n > 0
   order by 1
$function$
;
