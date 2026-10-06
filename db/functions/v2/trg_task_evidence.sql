-- v2.trg_task_evidence()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 095724c3cb2986c4fc41a3f74a077db1
CREATE OR REPLACE FUNCTION v2.trg_task_evidence()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if new.evidence_kind is null then
    if new.status = 'auto' then new.evidence_kind := 'auto';
    elsif new.kind in ('red_crescent','police','report_1919') then new.evidence_kind := 'external_report';
    else
      new.evidence_kind := coalesce(
        (select i.evidence_kind from v2.conduct_action_items i where i.id = new.item_id), 'note');
    end if;
  end if;
  return new;
end $function$
;
