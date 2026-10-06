-- v2.fn_clear_test(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1edb438f46b958a931f92b5a5e8c5a19
CREATE OR REPLACE FUNCTION v2.fn_clear_test(p_school uuid DEFAULT NULL::uuid)
 RETURNS TABLE("الجدول" text, "محذوف" integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t text; n int; sql text;
begin
  alter table v2.attendance disable trigger user;
  alter table v2.day_closures disable trigger user;

  delete from v2.event_deliveries d using v2.events e
   where d.event_id=e.id and e.is_test and (p_school is null or e.school_id=p_school);
  delete from v2.behavior_ledger bl using v2.behavior_records r where bl.record_id=r.id and r.is_test;
  delete from v2.behavior_tasks bt using v2.behavior_records r where bt.record_id=r.id and r.is_test;
  delete from v2.absence_tasks at2 using v2.absence_cases c where at2.case_id=c.id and c.is_test;
  delete from v2.incident_witnesses w using v2.behavior_records r where w.record_id=r.id and r.is_test;
  delete from v2.incident_seizures z using v2.behavior_records r where z.record_id=r.id and r.is_test;
  delete from v2.mail_acknowledgements ma using v2.incoming_mail m where ma.mail_id=m.id and m.is_test;
  delete from v2.mail_followups mf using v2.mail_items mi join v2.incoming_mail m on m.id=mi.mail_id
   where mf.item_id=mi.id and m.is_test;
  delete from v2.mail_targets mt using v2.mail_items mi join v2.incoming_mail m on m.id=mi.mail_id
   where mt.item_id=mi.id and m.is_test;
  delete from v2.mail_items mi using v2.incoming_mail m where mi.mail_id=m.id and m.is_test;
  delete from v2.mail_attachments ma2 using v2.incoming_mail m where ma2.mail_id=m.id and m.is_test;

  -- فكّ الإشارة إلى الأذونات قبل حذفها
  update v2.attendance set permit_id = null where is_test and permit_id is not null;

  foreach t in array array['attendance_ledger','behavior_records','absence_cases',
    'absence_excuse_claims','student_permissions','period_attendance','attendance',
    'entry_permits','dismissal_records','day_reversals','day_closures','events','incoming_mail'] loop
    if to_regclass('v2.'||t) is null then continue; end if;
    if p_school is null then
      sql := format('delete from v2.%I where is_test', t);
    elsif t in ('attendance_ledger','behavior_records','absence_cases','absence_excuse_claims','student_permissions') then
      sql := format('delete from v2.%I x where x.is_test and x.student_id in
        (select e.student_id from v2.enrolments e where e.school_id=%L)', t, p_school);
    else
      sql := format('delete from v2.%I where is_test and school_id=%L', t, p_school);
    end if;
    begin execute sql; get diagnostics n = row_count;
    exception when undefined_column then n := 0; end;
    if n > 0 then الجدول := t; محذوف := n; return next; end if;
  end loop;

  alter table v2.attendance enable trigger user;
  alter table v2.day_closures enable trigger user;
end $function$
;
