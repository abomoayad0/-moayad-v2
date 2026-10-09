-- v2.audit_state_vocabularies()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 443844e375cac0795c70af4364e73c29
CREATE OR REPLACE FUNCTION v2.audit_state_vocabularies()
 RETURNS TABLE(tbl text, rows_n integer, states text[], why_ar text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t text; v_n integer; v_def text; v_states text[]; v_all text[][] := array[]::text[][];
begin
  for t in select unnest(array['behavior_tasks','absence_tasks','mail_followups',
                               'behavior_records','absence_cases','outgoing_mail','incoming_mail',
                               'form_entries','counsel_cases']) loop
    if to_regclass('v2.'||t) is null then continue; end if;
    execute format('select count(*) from v2.%I', t) into v_n;
    select pg_get_constraintdef(c.oid) into v_def from pg_constraint c
     where c.conrelid = ('v2.'||t)::regclass and c.contype='c'
       and pg_get_constraintdef(c.oid) ~ 'status\s*=\s*ANY' limit 1;
    if v_def is null then continue; end if;
    select array_agg(m[1] order by m[1]) into v_states
      from regexp_matches(v_def, '''([a-z_]+)''::text', 'g') m;
    return query select t, v_n, v_states,
      'قاموسُ حالاتٍ مستقلّ — فما يُقبل في جدولٍ يُرفض في آخر، وقد وقع هذا في حال auto'::text;
  end loop;
end $function$
;
