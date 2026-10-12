-- v2.session_autoclose(p_school uuid)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 149cdcf5db20493475472384c653e97d
CREATE OR REPLACE FUNCTION v2.session_autoclose(p_school uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare n int := 0; g int;
begin
  if p_school is null then return 0; end if;
  g := (v2.rule_n(p_school,'session_autoclose_min'))::int;

  with due as (
    select s.id,
           case when s.attendance_at is null and s.lesson_ar is null
                  then 'أُقفلت آليًّا — بلا اعتماد حضورٍ ولا درس'
                when s.attendance_at is null then 'أُقفلت آليًّا — بلا اعتماد حضور'
                when s.lesson_ar is null     then 'أُقفلت آليًّا — بلا درس'
                else 'أُقفلت آليًّا — وكانت تامّة' end as why
      from v2.class_sessions s
      left join v2.period_slots ps
        on ps.school_id = s.school_id and ps.period_no = s.period_no
     where s.school_id = p_school
       and s.closed_at is null
       and (s.on_date < current_date
            or (ps.ends_at is not null
                and (now() at time zone 'Asia/Riyadh')::time
                    > (ps.ends_at + (g || ' minutes')::interval))))
  update v2.class_sessions t
     set closed_at = now(), auto_closed = true,
         note_ar = coalesce(nullif(btrim(t.note_ar),'') || ' · ', '') || d.why
    from due d
   where t.id = d.id;

  get diagnostics n = row_count;
  return n;
end $function$
;
