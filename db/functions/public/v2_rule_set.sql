-- public.v2_rule_set(p_school uuid, p_key text, p_value integer, p_why text)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 90ed03b1f0acaced06f956291835909f
CREATE OR REPLACE FUNCTION public.v2_rule_set(p_school uuid, p_key text, p_value integer, p_why text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare d record; v_old integer; v_min int;
begin
  perform v2.assert_role(array['principal','deputy','deputy_academic','deputy_students'],
                         'تغييرَ رقمٍ في مرجع الأرقام');
  perform v2.assert_my_school(p_school,'تغييرَ رقمٍ في مرجع الأرقام');

  select * into d from v2.rule_numbers where key=p_key and school_id is null;
  if d.id is null then
    raise exception 'الرقمُ «%» غيرُ مُعلَنٍ في مرجع الأرقام', p_key; end if;
  if not d.editable then
    raise exception 'الرقمُ «%» منصوصٌ في الدليل (%) فلا يُغيَّر — ونصُّه: %',
      d.label_ar, coalesce(d.source_ar,'—'), d.why_ar; end if;

  v_min := v2.rule_n(p_school,'reason_min_chars');
  if length(btrim(coalesce(p_why,''))) < v_min then
    raise exception 'تغييرُ رقمٍ لا يقع بلا سببٍ مكتوبٍ يبقى — وأقلُّه % حرفًا', v_min; end if;
  if p_value is null then raise exception 'اكتب القيمةَ الجديدة'; end if;
  if (d.min_n is not null and p_value < d.min_n) or (d.max_n is not null and p_value > d.max_n) then
    raise exception '«%» يكون بين % و% %', d.label_ar, d.min_n, d.max_n, d.unit_ar; end if;

  v_old := v2.rule_n(p_school,p_key);

  insert into v2.rule_numbers(school_id,key,label_ar,value_n,unit_ar,min_n,max_n,
         source_kind,source_ar,why_ar,editable,set_by)
  values (p_school,p_key,d.label_ar,p_value,d.unit_ar,d.min_n,d.max_n,
         'school',null,btrim(p_why),true,v2.current_person())
  on conflict (school_id,key) do update
    set value_n = excluded.value_n, why_ar = excluded.why_ar,
        set_by = excluded.set_by, set_at = now();

  return jsonb_build_object('ok',true,'key',p_key,'was',v_old,'now',p_value,
    'summary_ar','صار «'||d.label_ar||'» '||v2.ar_num(p_value)||' '||d.unit_ar||
      case when v_old <> p_value then ' (كان '||v2.ar_num(v_old)||')' else '' end,
    'note_ar','والسببُ محفوظٌ باسمك وتاريخه · والافتراضُ العامُّ لم يُمسّ، فهذا قرارُ مدرستك وحدَها.');
end $function$
;
