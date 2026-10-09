-- public.v2_day_mark_many(p_entries jsonb, p_date date)
-- مستخرَجٌ من القاعدة بـ pg_get_functiondef · md5 41428136adb090c390ce3ed5fc8692ab
CREATE OR REPLACE FUNCTION public.v2_day_mark_many(p_entries jsonb, p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'v2', 'public'
AS $function$
declare e jsonb; out_rows jsonb := '[]'::jsonb; r jsonb;
        n_ok integer := 0; n_bad integer := 0; n_case integer := 0;
begin
  perform v2.assert_attendance_hand('تسجيل سجلّ اليوم');
  if p_entries is null or jsonb_typeof(p_entries) <> 'array' or jsonb_array_length(p_entries) = 0 then
    raise exception 'لا طالبَ في الطلب — والقائمةُ تُرسل مصفوفةً: [{"student":"…","state":"absent"}]';
  end if;

  for e in select * from jsonb_array_elements(p_entries) loop
    begin
      r := public.v2_day_mark(
             (e->>'student')::uuid,
             e->>'state',
             p_date,
             nullif(e->>'minutes_late','')::smallint,
             nullif(e->>'note',''));
      n_ok := n_ok + 1;
      if r->'case' is not null and r->'case' <> 'null'::jsonb then n_case := n_case + 1; end if;
      out_rows := out_rows || jsonb_build_array(r);
    exception when others then
      n_bad := n_bad + 1;
      out_rows := out_rows || jsonb_build_array(jsonb_build_object(
        'ok', false, 'student', e->>'student', 'state', e->>'state',
        'why_ar', sqlerrm));
    end;
  end loop;

  return jsonb_build_object(
    'rows', out_rows,
    'counts', jsonb_build_object('ok',n_ok,'failed',n_bad,'cases',n_case),
    'summary_ar', 'سُجّل '||v2.ar_count(n_ok,'طالبٌ واحد','طالبان','طلّاب','طالبًا')||
      case when n_bad > 0 then ' · وتعذّر '||
        v2.ar_count(n_bad,'طالبٌ واحد','طالبان','طلّاب','طالبًا')||' ومعه سببُه' else '' end||
      case when n_case > 0 then ' · وفُتحت '||
        v2.ar_count(n_case,'حالةُ غيابٍ واحدة','حالتا غياب','حالاتِ غياب','حالةَ غياب') else '' end,
    'note_ar', 'وما تعذّر لم يُسكَت عنه — فلكلّ طالبٍ سطرُه وسببُه، ولا يُلفَّ الخطأُ في عدد');
end $function$
;
