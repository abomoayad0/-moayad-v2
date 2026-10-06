-- public.v2_entry_delegate(p_entry uuid, p_person uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 5ade140e07c14bd7b05a2618e550b950
CREATE OR REPLACE FUNCTION public.v2_entry_delegate(p_entry uuid, p_person uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare x record; o record;
begin
  select * into x from v2.merit_entries where id=p_entry;
  if x.id is null then raise exception 'المشاركةُ غيرُ موجودة'; end if;
  select * into o from v2.merit_opportunities where id=x.opp_id;
  if o.held_by is distinct from v2.current_person() and (v2.my_grant() is null or v2.my_grant() not in ('owner','admin')) then
    raise exception 'الإحالةُ لمن أقام الفرصة'; end if;
  if btrim(coalesce(p_note,''))='' then raise exception 'لا تُحال مشاركةٌ بلا سببٍ مكتوب'; end if;
  if x.verdict is not null then raise exception 'أُقرّت سلفًا'; end if;
  update v2.merit_entries set delegated_to=p_person, delegate_note=btrim(p_note) where id=p_entry;
  return jsonb_build_object('ok',true);
end $function$
;
