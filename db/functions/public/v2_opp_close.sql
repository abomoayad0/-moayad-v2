-- public.v2_opp_close(p_opp uuid, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 a3b613e8c5af92da076b75840b77721a
CREATE OR REPLACE FUNCTION public.v2_opp_close(p_opp uuid, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare o record; seat text;
begin
  select * into o from v2.merit_opportunities where id=p_opp;
  if o.id is null then raise exception 'الفرصةُ غيرُ موجودة'; end if;
  seat := v2.my_seat(o.school_id,'guidance');
  if seat is null and (v2.my_grant() is null or v2.my_grant() not in ('owner','admin')) then
    raise exception 'إغلاقُ الفرصة للجنة التوجيه'; end if;
  if o.state <> 'مفتوحة' then raise exception 'الفرصةُ % سلفًا', o.state; end if;
  if btrim(coalesce(p_why,''))='' then raise exception 'لا تُغلق فرصةٌ بلا سببٍ مكتوب'; end if;
  update v2.merit_opportunities set state='مُغلقة', close_why=btrim(p_why), closed_at=now()
   where id=p_opp;
  return jsonb_build_object('ok',true);
end $function$
;
