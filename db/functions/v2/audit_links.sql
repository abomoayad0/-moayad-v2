-- v2.audit_links()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 1445fbdd0e0b76415cf766809d1af27d
CREATE OR REPLACE FUNCTION v2.audit_links()
 RETURNS TABLE(tbl text, bound_to text, polymorphic boolean, rows_n integer, why_ar text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare r record; v_n integer;
begin
  for r in
    select c.conrelid::regclass::text tbl, c.confrelid::regclass::text ref
      from pg_constraint c
     where c.contype='f'
       and c.confrelid in ('v2.behavior_tasks'::regclass,'v2.absence_tasks'::regclass,
                           'v2.mail_followups'::regclass)
  loop
    execute format('select count(*) from %s', r.tbl) into v_n;
    return query select r.tbl, r.ref, false, v_n,
      'ربطٌ مشدودٌ إلى جدولِ بنودٍ واحد — وفي النظام ثلاثةٌ · '||
      'فما يُربط من أحدها لا يُربط من الآخرين'::text;
  end loop;
  if to_regclass('v2.outgoing_links') is not null then
    select count(*) into v_n from v2.outgoing_links;
    return query select 'v2.outgoing_links'::text, 'source + source_id'::text, true, v_n,
      'ربطٌ لا يعرف جنسَ البند — يقبل السلوكَ والمواظبةَ والوارد'::text;
  end if;
end $function$
;
