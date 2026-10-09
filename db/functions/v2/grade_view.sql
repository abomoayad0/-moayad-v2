-- v2.grade_view(p_domain text, p_points numeric, p_grade smallint, p_total numeric)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 e39dffee321976c0a578a53f7d3fd0e7
CREATE OR REPLACE FUNCTION v2.grade_view(p_domain text, p_points numeric, p_grade smallint, p_total numeric DEFAULT 100)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare v_upto numeric; v_label text; v_q boolean; v_cite text;
begin
  select value_num into v_upto from v2.conduct_rules where key='attendance.qualitative_upto_grade';
  v_q := p_grade is not null and coalesce(v_upto,2) >= p_grade;

  if v_q then
    select b.label_ar into v_label from v2.qualitative_bands b
     where b.domain = p_domain and p_points >= b.min_points
     order by b.min_points desc limit 1;
    select 'م'||article_no||' · '||source_doc||' '||source_page into v_cite
      from v2.conduct_rules where key='attendance.qualitative_grades';
  end if;

  return jsonb_build_object(
    'qualitative', v_q,
    'points', case when v_q then null else p_points end,
    'label_ar', v_label,
    'show_ar', case when v_q
      then 'تقديرُ المواظبة: '||coalesce(v_label,'—')
      else 'درجةُ المواظبة '||v2.ar_num(p_points)||' من '||v2.ar_num(p_total) end,
    'citation_ar', v_cite,
    'note_ar', case when v_q
      then 'الصفّان الأوّلُ والثاني بتقديرٍ كيفيٍّ لا برقم — ولا يُعرض لهما رقمٌ في بطاقةٍ ولا تقرير · '||
           'وحدودُ التقدير من لوحة التحكّم لا من الدليل'
      else null end);
end $function$
;
