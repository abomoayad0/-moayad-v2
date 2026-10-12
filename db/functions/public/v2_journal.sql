-- public.v2_journal(p_kind text, p_area text, p_state text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b88491aae5555c0bf186a942c32719e9
CREATE OR REPLACE FUNCTION public.v2_journal(p_kind text DEFAULT NULL::text, p_area text DEFAULT NULL::text, p_state text DEFAULT 'active'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_rows jsonb; v_n int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_school',
    'admin_assistant','info_registrar'],'قراءةَ سجلّ البناء');

  select coalesce(jsonb_agg(jsonb_build_object(
      'id',j.id,'kind',j.kind,'area_ar',j.area_ar,'title_ar',j.title_ar,
      'text_ar',j.text_ar,'said_by',j.said_by,'source_ar',j.source_ar,
      'state',j.state,'at',j.at,
      'kind_ar', case j.kind when 'rule' then '⚖️ قاعدة' when 'decision' then '✔️ قرار'
                             when 'deferred' then '⏳ مؤجّلة' when 'gap' then '🔴 ثغرة'
                             else '⚠️ خطأٌ مسجَّل' end)
      order by j.kind, j.ord, j.at),'[]'::jsonb), count(*)
    into v_rows, v_n
    from v2.build_journal j
   where (p_kind is null or j.kind = btrim(p_kind))
     and (p_area is null or j.area_ar ilike '%'||btrim(p_area)||'%')
     and (p_state is null or j.state = btrim(p_state));

  return jsonb_build_object('rows',v_rows,'count',v_n,
    'counts', (select jsonb_object_agg(k, c) from (
        select kind k, count(*) c from v2.build_journal
         where state = coalesce(btrim(p_state),state) group by kind) q),
    'summary_ar', case when coalesce(v_n,0)=0 then 'لا بندَ في السجلّ بهذي الصفة'
      else v2.ar_count(v_n,'بندٌ واحد','بندان','بنودٍ','بندًا')||' في سجلّ البناء' end,
    'note_ar','سجلُّ البناء: ما لا يُنسى. القواعدُ تُراعى في كلّ بناء، والمؤجّلاتُ محفوظةٌ لا منسيّة، والثغراتُ معلومةٌ لا مكتومة.');
end $function$
;
