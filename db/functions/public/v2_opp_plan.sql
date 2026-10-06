-- public.v2_opp_plan(p_opp uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 cb8a4f5f0ae3e976cc1cc67c566e241c
CREATE OR REPLACE FUNCTION public.v2_opp_plan(p_opp uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare o record; seat text; pend int;
begin
  select * into o from v2.merit_opportunities where id=p_opp;
  if o.id is null then raise exception 'الفرصةُ غيرُ موجودة'; end if;
  seat := v2.my_seat(o.school_id,'guidance');
  if seat is null and v2.my_grant() is null or v2.my_grant() not in ('owner','admin') then
    raise exception 'مخطّطُ الفرصة للجنة التوجيه'; end if;
  select count(*) into pend from v2.merit_entries
   where opp_id=p_opp and verdict is not null and graded_at is null;
  if pend > 0 then
    raise exception 'بقي % مشاركةً أُقرّت ولم تُقدَّر درجتُها', pend; end if;
  if btrim(coalesce(p_note,''))='' then raise exception 'لا يُعتمد مخطّطٌ بلا توصية'; end if;
  update v2.merit_opportunities
     set state='مُقدَّرة', plan_note=btrim(p_note), planned_at=now(),
         planned_by=v2.current_person()
   where id=p_opp;
  return jsonb_build_object('ok',true);
end $function$
;
