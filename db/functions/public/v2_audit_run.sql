-- public.v2_audit_run()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e8a9447e08b9da539e94301be366793e
CREATE OR REPLACE FUNCTION public.v2_audit_run()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n_new int := 0; n_again int := 0; n_fixed int := 0; n_open int; r jsonb; sw jsonb;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'تشغيلَ الجرد');

  select coalesce(jsonb_agg(jsonb_build_object(
           'check_key', z.check_key, 'object_ar', z.object_ar,
           'detail_ar', z.detail_ar, 'severity', z.severity)), '[]'::jsonb)
    into sw
    from (select distinct on (check_key, object_ar) * from v2.audit_sweep()
           order by check_key, object_ar) z;

  with s as (
    select * from jsonb_to_recordset(sw)
      as x(check_key text, object_ar text, detail_ar text, severity text)),
  up as (
    insert into v2.audit_findings(check_key,object_ar,detail_ar,severity)
    select s.check_key, s.object_ar, s.detail_ar, s.severity from s
    on conflict (check_key, object_ar) do update
      set last_seen = now(), seen_n = v2.audit_findings.seen_n + 1,
          detail_ar = excluded.detail_ar, severity = excluded.severity,
          resolved_at = null
    returning (v2.audit_findings.first_seen = v2.audit_findings.last_seen) as is_new)
  select count(*) filter (where is_new), count(*) filter (where not is_new)
    into n_new, n_again from up;

  update v2.audit_findings f set resolved_at = now()
   where f.resolved_at is null
     and not exists (select 1 from jsonb_to_recordset(sw)
                       as x(check_key text, object_ar text, detail_ar text, severity text)
                      where x.check_key = f.check_key and x.object_ar = f.object_ar);
  n_fixed := (select count(*) from v2.audit_findings
               where resolved_at >= now() - interval '1 minute');

  select count(*) into n_open from v2.audit_findings
   where resolved_at is null and waived_at is null;

  select coalesce(jsonb_agg(jsonb_build_object(
      'check', c.key, 'label_ar', c.label_ar, 'severity', c.severity,
      'open', (select count(*) from v2.audit_findings f
                where f.check_key=c.key and f.resolved_at is null and f.waived_at is null),
      'waived', (select count(*) from v2.audit_findings f
                where f.check_key=c.key and f.waived_at is not null),
      'fixed', (select count(*) from v2.audit_findings f
                where f.check_key=c.key and f.resolved_at is not null),
      'why_ar', c.why_ar, 'source_ar', c.source_ar) order by c.ord), '[]'::jsonb) into r
    from v2.audit_checks c where c.active;

  return jsonb_build_object('ok',true,'checks',r,
    'new',n_new,'again',n_again,'fixed_now',n_fixed,'open',n_open,
    'summary_ar','شُغّل الجرد — '||
      v2.ar_count(n_open,'خللٌ واحدٌ مفتوح','خللان مفتوحان','خللٍ مفتوح','خللًا مفتوحًا')||
      case when n_new>0 then ' · جديدٌ '||v2.ar_num(n_new) else '' end||
      case when n_fixed>0 then ' · أُصلح '||v2.ar_num(n_fixed) else '' end,
    'note_ar','يقول ولا يُصلح. ولكلّ خللٍ أوّلُ ظهورٍ وآخرُه وعددُ مرّاته — '
      ||'فالخللُ الراجعُ يُعرف أنّه رجع. ومن أراد إسقاطَ خللٍ أسقطه بسببٍ مكتوبٍ يبقى.');
end $function$
;
