-- v2.probe_run(p_door text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6f699953cbbf460ec38c5ca30720f305
CREATE OR REPLACE FUNCTION v2.probe_run(p_door text DEFAULT NULL::text)
 RETURNS TABLE(door text, probe_ar text, verdict text, said text)
 LANGUAGE plpgsql
AS $function$
declare r record; m text;
begin
  for r in select * from v2.door_probes dp
            where dp.active
              and (p_door is null or dp.door = p_door or dp.tag = p_door)
            order by dp.ord, dp.door loop
    if r.as_user is not null then
      perform set_config('request.jwt.claims',
        json_build_object('sub', r.as_user, 'role', 'authenticated')::text, true);
    end if;
    begin
      execute r.call_sql;
      raise exception 'PROBE_ACCEPTED';
    exception when others then
      m := sqlerrm;
      door := r.door; probe_ar := r.probe_ar;
      if m = 'PROBE_ACCEPTED' then
        verdict := 'قَبِل الخطأ'; said := '—';
      elsif m ~ '[ء-ي]' then
        verdict := 'ردٌّ عربيّ'; said := left(m, 170);
      else
        verdict := 'ردٌّ أعجميّ'; said := left(m, 170);
      end if;
    end;
    return next;
  end loop;
end $function$
;
