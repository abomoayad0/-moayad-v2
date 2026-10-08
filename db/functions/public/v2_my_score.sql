-- public.v2_my_score(p_student uuid, p_term smallint)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 b2aa36dd555938770d4ad38521e2c53b
CREATE OR REPLACE FUNCTION public.v2_my_score(p_student uuid, p_term smallint DEFAULT NULL::smallint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  who text; v_year uuid; v_sch uuid; v_term smallint; s jsonb;
  v_ded numeric; v_res numeric; v_mer numeric; v_open numeric;
begin
  who := v2.assert_student_or_kin(p_student,'درجةُ السلوك');

  select e.year_id, e.school_id into v_year, v_sch from v2.enrolments e
   where e.student_id=p_student and e.status='active' limit 1;
  if v_year is null then raise exception 'لا قيدَ فعّالٌ لك في سنةٍ دراسيّة'; end if;

  v_term := coalesce(p_term, v2.term_of_strict(v_sch, current_date), 1::smallint);
  s := v2.behavior_score(p_student, v_year, v_term);

  v_open := (s->>'opening')::numeric;
  v_ded  := (s->>'deducted')::numeric;
  v_res  := (s->>'restored')::numeric;
  v_mer  := (s->>'merit')::numeric;

  return jsonb_build_object(
    'term', v_term, 'term_ar', 'الفصلُ '||v2.ord_ar(v_term),
    'numbers', s,
    'line_ar',
      'سلوكُك: '||v2.ar_num(v_open)||
      case when v_ded > 0 then ' ⇐ حُسم '||v2.ar_num(v_ded) else '' end||
      case when v_res > 0 then ' ⇐ عوّضتَ '||v2.ar_num(v_res) else '' end||
      case when v_mer > 0 then ' ⇐ واكتسبتَ '||v2.ar_num(v_mer) else '' end||
      '  ⇒ '||v2.ar_num((s->>'total')::numeric),
    'what_ar', jsonb_build_object(
      'deducted', case when v_ded > 0
        then 'ما حُسم: '||v2.ar_num(v_ded)||' من درجة السلوك الإيجابيّ'
        else 'لم يُحسم منك شيءٌ هذا الفصل' end,
      'restored', case when v_res > 0
        then 'ما عوّضتَ: '||v2.ar_num(v_res)||' — أعادت ما حُسم، ولا ترفعك فوق الثمانين'
        else 'ولم تعوّض بعد — وبابُ التعويض مفتوح' end,
      'merit', case when v_mer > 0
        then 'وما اكتسبتَ: '||v2.ar_num(v_mer)||' — زيادةٌ لك من درجات التميّز، وسقفُها عشرون'
        else 'وما اكتسبتَ: لا شيءَ بعد — ودرجاتُ التميّز عشرون مستقلّةٌ عن السلوك' end,
      'ceiling', 'والسلوكُ لا يتجاوز ثمانين · والتميّزُ عشرين · والمجموعُ مئة'),
    'rows', jsonb_build_object(
      'deductions', coalesce((select jsonb_agg(jsonb_build_object(
            'on', bl.created_at::date, 'points', -bl.points, 'why', bl.reason)
            order by bl.created_at)
          from v2.behavior_ledger bl
          where bl.student_id=p_student and bl.year_id=v_year and bl.term_no=v_term
            and bl.kind='deduction'), '[]'::jsonb),
      'compensations', coalesce((select jsonb_agg(jsonb_build_object(
            'on', bl.created_at::date, 'points', bl.points, 'why', bl.reason)
            order by bl.created_at)
          from v2.behavior_ledger bl
          where bl.student_id=p_student and bl.year_id=v_year and bl.term_no=v_term
            and bl.kind='compensation'), '[]'::jsonb),
      'merits', coalesce((select jsonb_agg(jsonb_build_object(
            'on', bl.created_at::date, 'points', bl.points, 'why', bl.reason)
            order by bl.created_at)
          from v2.behavior_ledger bl
          where bl.student_id=p_student and bl.year_id=v_year and bl.term_no=v_term
            and bl.kind='merit'), '[]'::jsonb)),
    'open_opportunities', (select count(*) from v2.merit_opportunities o
        where o.school_id=v_sch and o.state='مفتوحة'),
    'seen_as', who);
end
$function$
;
