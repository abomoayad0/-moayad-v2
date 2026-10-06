-- public.v2_opp_plan(p_opp uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 2333aeacdc9098eab244c872dad1c783
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
  if seat is null and (v2.my_grant() is null or v2.my_grant() not in ('owner','admin')) then
    raise exception 'مخطّطُ الفرصة للجنة التوجيه'; end if;
  if o.state = 'مُقدَّرة' then
    raise exception 'اعتُمد مخطّطُ هذي الفرصة سلفًا — ولا يُعتمد مرّتين'; end if;
  if o.state = 'ملغاة' then raise exception 'فرصةٌ ملغاةٌ لا يُعتمد مخطّطُها'; end if;

  -- 🔑 من نفّذ أو نفّذ جزئيًّا يلزمه تقدير · ومن لم ينفّذ أو لم يحضر لا يُنتظر
  select count(*) into pend from v2.merit_entries
   where opp_id=p_opp and verdict in ('نفّذ','نفّذ جزئيًّا') and graded_at is null;
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
