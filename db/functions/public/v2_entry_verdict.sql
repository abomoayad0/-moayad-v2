-- public.v2_entry_verdict(p_entry uuid, p_verdict text, p_note text, p_file text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 eab53ad526ede0ac6e1d2831044dee7e
CREATE OR REPLACE FUNCTION public.v2_entry_verdict(p_entry uuid, p_verdict text, p_note text, p_file text)
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
  if coalesce(x.delegated_to, o.held_by) is distinct from v2.current_person()
     and (v2.my_grant() is null or v2.my_grant() not in ('owner','admin')) then
    raise exception 'الإقرارُ لمن أقام الفرصةَ أو لمن أُحيل إليه'; end if;
  if p_verdict not in ('نفّذ','نفّذ جزئيًّا','لم ينفّذ','لم يحضر') then
    raise exception 'الحكم: نفّذ · نفّذ جزئيًّا · لم ينفّذ · لم يحضر'; end if;
  if btrim(coalesce(p_note,''))='' then raise exception 'اكتب ما لاحظتَه — إلزاميّ'; end if;
  if x.graded_at is not null then
    raise exception 'قُدّرت درجةُ هذي المشاركة — فلا يُبدَّل حكمُها'; end if;
  if o.state = 'مُقدَّرة' then
    raise exception 'اعتُمد مخطّطُ الفرصة — فلا يُبدَّل حكمٌ فيها'; end if;
  if x.filed_at is null and p_verdict in ('نفّذ','نفّذ جزئيًّا') then
    raise exception 'لم يرفع الطالبُ نموذجَه بعد — ولا يُقرُّ تنفيذٌ بلا نموذجٍ وشاهد'; end if;

  update v2.merit_entries
     set verdict_prev = case when x.verdict is distinct from p_verdict then x.verdict end,
         verdict_changed_at = case when x.verdict is not null
                                   and x.verdict is distinct from p_verdict then now() end,
         verdict=p_verdict, verdict_note=btrim(p_note),
         verdict_file=nullif(btrim(coalesce(p_file,'')),''),
         verdict_by=v2.current_person(), verdict_at=now()
   where id=p_entry;
  return jsonb_build_object('ok',true,'verdict',p_verdict,
    'changed_from', case when x.verdict is distinct from p_verdict then x.verdict end);
end $function$
;
