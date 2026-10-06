-- v2.trg_abs_task_evidence()
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 f914680a003d95718ea28e15c6b98067
CREATE OR REPLACE FUNCTION v2.trg_abs_task_evidence()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'v2', 'public'
AS $function$
begin
  if new.evidence_kind is null then
    if new.status = 'auto' then new.evidence_kind := 'auto';
    else
      new.evidence_kind := coalesce(
        (select i.evidence_kind from v2.absence_ladder_items i where i.id = new.item_id), 'note');
    end if;
  end if;
  return new;
end $function$
;
