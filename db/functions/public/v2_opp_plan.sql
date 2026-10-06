-- public.v2_opp_plan(p_opp uuid, p_note text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 6d510bdc98ae732961d3743b230f063e
CREATE OR REPLACE FUNCTION public.v2_opp_plan(p_opp uuid, p_note text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare o record; seat text; pend int; nover int;
begin
  select * into o from v2.merit_opportunities where id=p_opp;
  if o.id is null then raise exception 'الفرصةُ غيرُ موجودة'; end if;
  seat := v2.my_seat(o.school_id,'guidance');
  if seat is null and (v2.my_grant() is null or v2.my_grant() not in ('owner','admin')) then
    raise exception 'مخطّطُ الفرصة للجنة التوجيه'; end if;
  if o.state = 'مُقدَّرة' then
    raise exception 'اعتُمد مخطّطُ هذي الفرصة سلفًا — ولا يُعتمد مرّتين'; end if;
  if o.state = 'ملغاة' then raise exception 'فرصةٌ ملغاةٌ لا يُعتمد مخطّطُها'; end if;
  if o.state = 'مفتوحة' then
    raise exception 'الفرصةُ ما زالت مفتوحةً — أغلقها أوّلًا'; end if;

  select count(*) into nover from v2.merit_entries
   where opp_id=p_opp and verdict is null;
  if nover > 0 then
    raise exception 'بقي % مشاركًا بلا حكم — أقرّ لكلٍّ حكمَه، ومن لم يحضر فـ«لم يحضر»',
      v2.ar_num(nover); end if;

  select count(*) into pend from v2.merit_entries
   where opp_id=p_opp and verdict in ('نفّذ','نفّذ جزئيًّا') and graded_at is null;
  if pend > 0 then
    raise exception 'بقي % مشاركةً أُقرّت ولم تُقدَّر درجتُها', v2.ar_num(pend); end if;
  if btrim(coalesce(p_note,''))='' then raise exception 'لا يُعتمد مخطّطٌ بلا توصية'; end if;

  update v2.merit_opportunities
     set state='مُقدَّرة', plan_note=btrim(p_note), planned_at=now(),
         planned_by=v2.current_person()
   where id=p_opp;
  return jsonb_build_object('ok',true);
end $function$
;
