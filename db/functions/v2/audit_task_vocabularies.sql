-- v2.audit_task_vocabularies()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f17ca765044f71c14932af8ec423bf14
CREATE OR REPLACE FUNCTION v2.audit_task_vocabularies()
 RETURNS TABLE(tbl text, family_ar text, rows_n integer, states text[], canon text[], diverges boolean, why_ar text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare t text; fam text; v_n integer; v_def text; v_states text[]; v_canon text[];
begin
  for t, fam in select * from (values
      ('behavior_tasks','بنود'),('absence_tasks','بنود'),('mail_followups','بنود'),
      ('behavior_records','كيان'),('absence_cases','كيان'),('outgoing_mail','كيان'),
      ('incoming_mail','كيان'),('form_entries','كيان'),('counsel_cases','كيان')) v loop
    if to_regclass('v2.'||t) is null then continue; end if;
    execute format('select count(*) from v2.%I', t) into v_n;
    select pg_get_constraintdef(c.oid) into v_def from pg_constraint c
     where c.conrelid = ('v2.'||t)::regclass and c.contype='c'
       and pg_get_constraintdef(c.oid) ~ 'status\s*=\s*ANY' limit 1;
    if v_def is null then continue; end if;
    select array_agg(m[1] order by m[1]) into v_states
      from regexp_matches(v_def, '''([a-z_]+)''::text', 'g') m;
    select array_agg(distinct v2.task_state(s) order by v2.task_state(s)) into v_canon
      from unnest(v_states) s;
    return query select t, fam, v_n, v_states, v_canon,
      (fam = 'بنود' and not (v_canon <@ array['open','standing','done','skipped','refused'])),
      case when fam = 'كيان'
        then 'كيانٌ له دورةُ حياةٍ خاصّةٌ به — واختلافُها ليس تكرارًا'
        else 'جدولُ بنودٍ — وقاموسُه يُترجَم إلى الحال المعياريّة بـ v2.task_state' end::text;
  end loop;
end $function$
;
